// S3-triggered Lambda: compresses a freshly-uploaded exercise video with
// ffmpeg and writes the result to the "final" (canonical) S3 key that the
// Rails app already treats as `exercise.video_url` from the moment the
// presigned upload URL was issued. No callback to Rails, no DB update —
// see clinic-for-life-backend/docs/video-compression.md for why.
import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { spawn } from "node:child_process";
import { createReadStream, createWriteStream } from "node:fs";
import { unlink } from "node:fs/promises";
import { pipeline } from "node:stream/promises";
import { randomUUID } from "node:crypto";
import path from "node:path";

const s3 = new S3Client({});
const FFMPEG_PATH = process.env.FFMPEG_PATH || "/opt/bin/ffmpeg";
const RAW_SEGMENT = "uploads/raw/";
const FINAL_SEGMENT = "uploads/";

export const handler = async (event) => {
  for (const record of event.Records) {
    await processRecord(record);
  }
};

async function processRecord(record) {
  const bucket = record.s3.bucket.name;
  const rawKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
  const log = (extra) => console.log(JSON.stringify({ bucket, rawKey, ...extra }));

  if (!rawKey.includes(RAW_SEGMENT)) {
    log({ msg: "skip: key does not contain expected raw/ segment" });
    return;
  }

  const finalKey = rawKey.replace(RAW_SEGMENT, FINAL_SEGMENT);
  const tmpIn = `/tmp/${randomUUID()}${path.extname(rawKey) || ".mp4"}`;
  const tmpOut = `/tmp/${randomUUID()}-out.mp4`;

  log({ msg: "start", finalKey });
  try {
    await downloadToFile(bucket, rawKey, tmpIn);
    await runFfmpeg(tmpIn, tmpOut, log);
    await uploadFile(bucket, finalKey, tmpOut);
    log({ msg: "done", finalKey });
  } catch (err) {
    log({ msg: "FAILED", finalKey, error: err.message });
    // Rethrow so Lambda's default async-invoke retry (2 attempts) kicks in.
    // If all retries fail, the final key is never created — see the
    // manual-recovery runbook in docs/video-compression.md (must happen
    // within the raw_upload_expiration_days window before the raw object
    // is lifecycle-expired).
    throw err;
  } finally {
    await Promise.allSettled([unlink(tmpIn), unlink(tmpOut)]);
  }
}

async function downloadToFile(bucket, key, dest) {
  const { Body } = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
  await pipeline(Body, createWriteStream(dest));
}

function runFfmpeg(input, output, log) {
  return new Promise((resolve, reject) => {
    const args = [
      "-y",
      "-i", input,
      // Cap at 720p, never upscale, preserve aspect ratio.
      "-vf", "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease",
      "-c:v", "libx264",
      "-preset", "fast",
      "-crf", "26",
      "-c:a", "aac",
      "-b:a", "128k",
      // Moves the moov atom to the front so playback can start before the
      // full file downloads (matters since the app streams straight from
      // a presigned S3 GET URL, not through a media server).
      "-movflags", "+faststart",
      output,
    ];

    const proc = spawn(FFMPEG_PATH, args);
    let stderrTail = "";
    proc.stderr.on("data", (chunk) => {
      // ffmpeg's stderr is huge and mostly progress noise — keep only the
      // tail so a single CloudWatch log line stays useful, not flooded.
      stderrTail = (stderrTail + chunk.toString()).slice(-4000);
    });
    proc.on("error", reject); // e.g. binary missing/not executable — layer misconfigured
    proc.on("close", (code) => {
      if (code === 0) {
        log({ msg: "ffmpeg ok" });
        resolve();
      } else {
        reject(new Error(`ffmpeg exited ${code}: ${stderrTail}`));
      }
    });
  });
}

async function uploadFile(bucket, key, filePath) {
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: createReadStream(filePath),
      ContentType: "video/mp4",
    }),
  );
}

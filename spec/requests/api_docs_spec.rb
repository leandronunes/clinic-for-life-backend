require "rails_helper"

RSpec.describe "API docs", type: :request do
  it "serves the OpenAPI document" do
    get "/api-docs/v1/swagger.yaml"

    expect(response).to have_http_status(:ok)

    spec = YAML.safe_load(response.body)
    expect(spec["openapi"]).to eq("3.0.3")
    expect(spec["paths"]).to have_key("/api/v1/auth/login")
  end

  it "serves the Swagger UI" do
    get "/api-docs/index.html"

    expect(response).to have_http_status(:ok)
  end
end

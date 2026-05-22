module Boldsign
  module Resources
    # Plan / billing endpoints (`/v1/plan/*`).
    class Plan < Resource
      def api_credits_count; @client.get("/v1/plan/apiCreditsCount"); end
    end
  end
end

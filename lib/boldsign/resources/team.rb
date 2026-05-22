module Boldsign
  module Resources
    # Team endpoints (`/v1/teams/*`).
    class Team < Resource
      def list(**params); @client.get("/v1/teams/list", params); end
      def get(team_id);   @client.get("/v1/teams/get", teamId: team_id); end
      def create(body);   @client.post("/v1/teams/create", body: body); end
      def update(body, **params); @client.put("/v1/teams/update", body: body, params: params); end
    end
  end
end

/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.role ~ \"Shift Leader\" ||\n@request.auth.role ~ \"Kitchen Leader\" ||\n@request.auth.role ~ \"Hospitality Manager\" ||\n@request.auth.role ~ \"Branch Manager\" ||\n@request.auth.role ~ \"Admin\"",
    "deleteRule": "@request.auth.role ~ \"Shift Leader\" ||\n@request.auth.role ~ \"Kitchen Leader\" ||\n@request.auth.role ~ \"Hospitality Manager\" ||\n@request.auth.role ~ \"Branch Manager\" ||\n@request.auth.role ~ \"Admin\"",
    "updateRule": "@request.auth.role ~ \"Shift Leader\" ||\n@request.auth.role ~ \"Kitchen Leader\" ||\n@request.auth.role ~ \"Hospitality Manager\" ||\n@request.auth.role ~ \"Branch Manager\" ||\n@request.auth.role ~ \"Admin\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update collection data
  unmarshal({
    "createRule": "",
    "deleteRule": "",
    "updateRule": ""
  }, collection)

  return app.save(collection)
})

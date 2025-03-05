/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update collection data
  unmarshal({
    "deleteRule": "@request.auth.role ~ \"Shift Leader\" ||\n@request.auth.role ~ \"Kitchen Leader\" ||\n@request.auth.role ~ \"Hospitality Manager\" ||\n@request.auth.role ~ \"Branch Manager\" ||\n@request.auth.role ~ \"Admin\"",
    "updateRule": "@request.auth.role ~ \"Shift Leader\" ||\n@request.auth.role ~ \"Kitchen Leader\" ||\n@request.auth.role ~ \"Hospitality Manager\" ||\n@request.auth.role ~ \"Branch Manager\" ||\n@request.auth.role ~ \"Admin\"",
    "viewRule": ""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update collection data
  unmarshal({
    "deleteRule": null,
    "updateRule": null,
    "viewRule": null
  }, collection)

  return app.save(collection)
})

/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.role ~ \"Shift Leader\" ||\n@request.auth.role ~ \"Kitchen Leader\" ||\n@request.auth.role ~ \"Hospitality Manager\" ||\n@request.auth.role ~ \"Branch Manager\" ||\n@request.auth.role ~ \"Admin\"",
    "deleteRule": null,
    "listRule": null,
    "updateRule": null,
    "viewRule": null
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update collection data
  unmarshal({
    "createRule": "",
    "deleteRule": "",
    "listRule": "",
    "updateRule": "",
    "viewRule": ""
  }, collection)

  return app.save(collection)
})

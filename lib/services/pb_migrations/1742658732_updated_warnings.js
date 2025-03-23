/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_688373259")

  // update collection data
  unmarshal({
    "listRule": ""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_688373259")

  // update collection data
  unmarshal({
    "listRule": "user = @request.auth.id"
  }, collection)

  return app.save(collection)
})

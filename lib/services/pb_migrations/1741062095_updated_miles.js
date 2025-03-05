/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3131297699")

  // update collection data
  unmarshal({
    "name": "mileage"
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3131297699")

  // update collection data
  unmarshal({
    "name": "miles"
  }, collection)

  return app.save(collection)
})

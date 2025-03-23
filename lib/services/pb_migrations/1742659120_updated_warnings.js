/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_688373259")

  // add field
  collection.fields.addAt(6, new Field({
    "hidden": false,
    "id": "bool433807228",
    "name": "acknowledged",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  // add field
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "date3269887158",
    "max": "",
    "min": "",
    "name": "acknowledged_at",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_688373259")

  // remove field
  collection.fields.removeById("bool433807228")

  // remove field
  collection.fields.removeById("date3269887158")

  return app.save(collection)
})

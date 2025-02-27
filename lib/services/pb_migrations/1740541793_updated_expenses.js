/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1691921218")

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "select105650625",
    "maxSelect": 1,
    "name": "category",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Food",
      "Rent",
      "Supplies",
      "Utilities",
      "Transport",
      "Miscellaneous"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1691921218")

  // remove field
  collection.fields.removeById("select105650625")

  return app.save(collection)
})

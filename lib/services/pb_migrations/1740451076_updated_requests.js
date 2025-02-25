/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1003195976")

  // add field
  collection.fields.addAt(10, new Field({
    "hidden": false,
    "id": "select1736193922",
    "maxSelect": 1,
    "name": "urgency",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Low",
      "Medium",
      "High"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1003195976")

  // remove field
  collection.fields.removeById("select1736193922")

  return app.save(collection)
})

/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // remove field
  collection.fields.removeById("text3616816488")

  // add field
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "select3616816488",
    "maxSelect": 1,
    "name": "area",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "Kitchen",
      "Customer Service"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // add field
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3616816488",
    "max": 0,
    "min": 0,
    "name": "area",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // remove field
  collection.fields.removeById("select3616816488")

  return app.save(collection)
})

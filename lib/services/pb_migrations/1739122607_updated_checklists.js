/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // remove field
  collection.fields.removeById("date1345189255")

  // remove field
  collection.fields.removeById("date1096160257")

  // add field
  collection.fields.addAt(9, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text1345189255",
    "max": 0,
    "min": 0,
    "name": "start_time",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(10, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text1096160257",
    "max": 0,
    "min": 0,
    "name": "end_time",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "date1345189255",
    "max": "",
    "min": "",
    "name": "start_time",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "date1096160257",
    "max": "",
    "min": "",
    "name": "end_time",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // remove field
  collection.fields.removeById("text1345189255")

  // remove field
  collection.fields.removeById("text1096160257")

  return app.save(collection)
})

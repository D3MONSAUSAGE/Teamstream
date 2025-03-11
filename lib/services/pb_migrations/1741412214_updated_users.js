/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // add field
  collection.fields.addAt(18, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3616816488",
    "max": 0,
    "min": 0,
    "name": "area",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(19, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text1177347317",
    "max": 0,
    "min": 0,
    "name": "position",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(20, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text4042183640",
    "max": 0,
    "min": 0,
    "name": "street",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(21, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text760939060",
    "max": 0,
    "min": 0,
    "name": "city",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(22, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text2744374011",
    "max": 0,
    "min": 0,
    "name": "state",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(23, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text2712461656",
    "max": 0,
    "min": 0,
    "name": "zip_code",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(24, new Field({
    "hidden": false,
    "id": "date2657682032",
    "max": "",
    "min": "",
    "name": "food_cert_expiry",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(25, new Field({
    "hidden": false,
    "id": "date3548443991",
    "max": "",
    "min": "",
    "name": "alcohol_cert_expiry",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // remove field
  collection.fields.removeById("text3616816488")

  // remove field
  collection.fields.removeById("text1177347317")

  // remove field
  collection.fields.removeById("text4042183640")

  // remove field
  collection.fields.removeById("text760939060")

  // remove field
  collection.fields.removeById("text2744374011")

  // remove field
  collection.fields.removeById("text2712461656")

  // remove field
  collection.fields.removeById("date2657682032")

  // remove field
  collection.fields.removeById("date3548443991")

  return app.save(collection)
})

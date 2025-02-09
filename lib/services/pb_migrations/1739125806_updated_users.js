/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // remove field
  collection.fields.removeById("text1466534506")

  // remove field
  collection.fields.removeById("text990738133")

  // add field
  collection.fields.addAt(16, new Field({
    "hidden": false,
    "id": "select1466534506",
    "maxSelect": 1,
    "name": "role",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "Regular User",
      "Shift Leader",
      "Kitchen Leader",
      "Hospitality Manager",
      "Branch Manager",
      "Admin"
    ]
  }))

  // add field
  collection.fields.addAt(17, new Field({
    "hidden": false,
    "id": "json990738133",
    "maxSize": 0,
    "name": "certifications",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "json"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // add field
  collection.fields.addAt(8, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text1466534506",
    "max": 0,
    "min": 0,
    "name": "role",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(14, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text990738133",
    "max": 0,
    "min": 0,
    "name": "certifications",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // remove field
  collection.fields.removeById("select1466534506")

  // remove field
  collection.fields.removeById("json990738133")

  return app.save(collection)
})

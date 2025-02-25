/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1003195976")

  // add field
  collection.fields.addAt(11, new Field({
    "hidden": false,
    "id": "bool1804889986",
    "name": "is_recurring",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  // add field
  collection.fields.addAt(12, new Field({
    "hidden": false,
    "id": "select590608952",
    "maxSelect": 1,
    "name": "recurring_type",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Daily",
      "Weekly",
      "Monthly"
    ]
  }))

  // add field
  collection.fields.addAt(13, new Field({
    "hidden": false,
    "id": "date589766077",
    "max": "",
    "min": "",
    "name": "next_occurence",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1003195976")

  // remove field
  collection.fields.removeById("bool1804889986")

  // remove field
  collection.fields.removeById("select590608952")

  // remove field
  collection.fields.removeById("date589766077")

  return app.save(collection)
})

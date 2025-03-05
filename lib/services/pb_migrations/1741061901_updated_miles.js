/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3131297699")

  // add field
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "number1910862152",
    "max": null,
    "min": null,
    "name": "miles",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "select1001949196",
    "maxSelect": 1,
    "name": "reason",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Work Assignment",
      "Client Visit",
      "Other"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3131297699")

  // remove field
  collection.fields.removeById("number1910862152")

  // remove field
  collection.fields.removeById("select1001949196")

  return app.save(collection)
})

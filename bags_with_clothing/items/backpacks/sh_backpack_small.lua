ITEM.name = "Small Bag"
ITEM.desc = "A small bag that does not carry much."
ITEM.model = "models/fallout 3/backpack_1.mdl"
ITEM.bagUniqueID = 1
ITEM.width = 3
ITEM.height = 3
ITEM.invWidth = 4
ITEM.invHeight = 4
ITEM.flag = "y"
ITEM.price = 950

if (CLIENT) then
    util.PrecacheModel( ITEM.model )
end
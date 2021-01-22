function locateItem (locateItemName)
    -- Loops through the inventory to find the specified item
    -- Returns position of first instace
    for i=1, 16 do
        local itemData = turtle.getItemDetail(i)
        if itemData then
            local currentItemName = itemData.name
            if currentItemName == locateItemName then
                return i
            end
        end
    end
    return false
end

function equipItem (itemName, side)
    -- Locates an item and equips it on the specified side
    local itemPos = locateItem(itemName)
    if itemPos then
        local couldSelect, err = turtle.select(itemPos)
        if not couldSelect then
            print(err)
            return false
        end
        if string.lower(side) == "right" then
            turtle.equipRight()
            return true
        elseif string.lower(side) == "left" then
            turtle.equipLeft()
            return true
        else
            print("Invalid side selection")
            return false
        end
    else
        print("Could not find inventory slot")
        return false
    end
end

function refuel(fuelItem)
    -- If specified the function will refuel with specific item.
    -- Otherwise it will refuel with the first occurring item of the fuelItems list
    local fuelItems = {
        "minecraft:coal",
        "minecraft:lava_bucket",
        "minecraft:stick",
    }
    if fuelItem then
        -- Atempt to locate the specified fuelItem
        local itemPos = locateItem(fuelItem)
        if itemPos then
            turtle.select(itemPos)
            local itemCount = turtle.getItemCount(itemPos)
            turtle.refuel(itemCount)
            return true
        else
            print("Could not find fuelItem")
            return false
        end
    else
        -- Loop through the fuelItems list and refuels with the first occurring item
        -- Return false if no items are found
        for key, item in next, fuelItems do
            local itemPos = locateItem(item)
            if itemPos then
                turtle.select(itemPos)
                local itemCount = turtle.getItemCount(itemPos)
                turtle.refuel(itemCount)
                return true
            end
        end
        print("No fuel items found")
        return false
    end
end

function hardMove(direction)
    -- Atempt to move the turtle in a specified direction
    -- If not possible refuel and breaking obstruction will be atempted
    -- TODO: Add y level corigation
    local couldMove, moveErr, lowerDirection
    lowerDirection = string.lower(direction)
    -- Determine direction and try to move in the direction
    if lowerDirection == "up" then
        couldMove, moveErr = turtle.up()
    elseif lowerDirection == "down" then
        couldMove, moveErr = turtle.down()
    elseif lowerDirection == "forward" then
        couldMove, moveErr = turtle.forward()
    elseif lowerDirection == "back" then
        couldMove, moveErr = turtle.back()
    end
    -- Error handling if it was unable to move
    if not couldMove then
        if moveErr == "Out of fuel" then
            -- Try to refuel
            if not refuel() then return false end
            return hardMove(direction)
        elseif moveErr == "Movement obstructed" then
            -- If the movement is obstructed try to mine the block in the direction
            -- If the block can't be broken print the error and return false
            if lowerDirection == "up" then
                local broken, digErr = turtle.digUp()
                if not broken then
                    print(digErr)
                    return false
                end
            elseif lowerDirection == "down" then
                local broken, digErr = turtle.digDown()
                if not broken then
                    print(digErr)
                    return false
                end
            elseif lowerDirection == "forward" then
                local broken, digErr = turtle.dig()
                if not broken then
                    print(digErr)
                    return false
                end
            elseif lowerDirection == "back" then
                -- TODO: Add error correction
                print("Movment obstructed backwords")
                return false
            end
            return hardMove(direction)
        else
            print("Unhandled error in hardmove")
            return false
        end
    else
        return true
    end
end

function mineTree ()
    -- Mines a tree from bottom to top
    -- Asumes tree is vertical and no blocks missing
    local moveUpCount = 0
    -- EquipItem is not error handled because a more general error handler comes later after turtle.dig() 
    equipItem("minecraft:diamond_pickaxe")
    local blockInFront, blockData = turtle.inspect()
    while blockInFront and (string.sub(blockData.name, string.len(blockData.name)-2) == "log") do
        while blockInFront do
            local broken, digErr = turtle.dig()
            if not broken then
                print(digErr)
                -- Returns true because mineTree is not mission critical
                return true
            end
            blockInFront, blockData = turtle.inspect()
        end
        if not hardMove("up") then
            break
        else
            moveUpCount = moveUpCount + 1 
        end
        blockInFront, blockData = turtle.inspect()
    end
    for i=0, moveUpCount-1 do
        hardMove("down")
    end
    return true
end

function searchSurface(condition, blockTable)
    for i = 0, 4, 1 do
        for i = 0, 16, 1 do
            if not scanWithAction(blockTable) then return false end
            if not moveAlongGround() then return false end
            if condition() then return true end
        end
        -- Some unnesesary scanning oppon
        -- TODO: Fix:
        -- If the turningpoint is floating above the ground it will move down and turn back on itself
        -- Temp/permanent hack is to include blockBellow as true when turning
        if (-1)^i > 0 then
            turtle.turnRight()
            if not scanWithAction(blockTable) then return false end
            if not moveAlongGround(true) then return false end
            turtle.turnRight()
        else
            turtle.turnLeft()
            if not scanWithAction(blockTable) then return false end
            if not moveAlongGround(true) then return false end
            turtle.turnLeft()
        end
    end
end

function stripMine(condition)
    local blockBellow, blockData = turtle.inspectDown()
    while blockBellow do
        if blockData.name == "minecraft:bedrock" then
            yLevel = 6
            scanWithAction(blockTable, true)
        end
    end
end

function bedrockHandler(direction)
    if not direction then
        yLevel = 5
        if not hardMove("up") or not hardMove("forward") then return false end
        return true
    elseif direction == "down" then
        yLevel = 6
        return true
    elseif direction == "up" then
        yLevel = 4
        if not hardMove("back") or not hardMove("up") or not hardMove("forward") then return false end
        return true
    else
        print("Direction argument not recogniced in bedrockHandler")
        return false
    end
end

function mineOre(direction)
    if not direction then
        if not hardMove("forward") then
            return false
        elseif not scanWithAction(blockTable, true) then
            return false
        else
            return hardMove("back")
        end
    elseif direction=="top" then
        if not hardMove("up") then
            return false
        elseif not scanWithAction(blockTable, true) then
            return false
        else
            return hardMove("down")
        end
    elseif direction=="bottom" then
        if not hardMove("down") then
            return false
        elseif not scanWithAction(blockTable, true) then
            return false
        else
            return hardMove("up")
        end
    end
end

function moveAlongGround(blockBellow)
    if not blockBellow then
        local couldMove, err = turtle.down()
        if not couldMove then
            if err == "Out of fuel" then
                if not refuel() then return false end
                return moveAlongGround(false)
            end
            return moveAlongGround(true)
        else
            return true
        end
    else
        local couldMove, err = turtle.forward()
        if not couldMove then
            if err == "Out of fuel" then
                if not refuel() then return false end
                return moveAlongGround(false)
            else
                couldMove, err = turtle.up()
                if not couldMove then
                    local couldDig, err = turtle.digUp()
                    if not couldDig then return false end
                    return moveAlongGround(blockBellow)
                else
                    scanWithAction(blockTable)
                    return moveAlongGround(blockBellow)
                end
            end
        else
            return true
        end
    end
end

function scanWithAction(table, topAndBottom)
    -- Takes a table with format {[block]=action, ...}
    -- TODO: Fix variable redefinition in topAndBottom handler
    turtle.turnLeft()
    local blockInFront, blockData = turtle.inspect()
    local actionStatus = true
    if blockInFront then
        for block, action in next, table do
            if blockData.name == block then
                actionStatus = action()
            end
        end
    end
    for i = 1, 2 do
        turtle.turnRight()
        blockInFront, blockData = turtle.inspect()
        if blockInFront then
            for block, action in next, table do
                if blockData.name == block then
                    actionStatus = action()
                end
            end
        end
    end
    turtle.turnLeft()
    if topAndBottom then
        local blockBellow, blockData = turtle.inspectDown()
        if blockBellow then
            for block, action in next, table do
                if blockData.name == block then
                    actionStatus = action("bottom")
                end
            end
        end
        local blockOver, blockData = turtle.inspectUp()
        if blockOver then
            for block, action in next, table do
                if blockData.name == block then
                    actionStatus = action("top")
                end
            end
        end
    end
    return actionStatus
end

function woodLevelReached()
    local itemPos = locateItem("minecraft:spruce_log")
    if itemPos then
        if (turtle.getItemCount(itemPos) >= 7) then
            return true
        else
            return false
        end
    else
        return false
    end
end

function oreLevelReached(table)
    --Create better condition some ores are not ores
    for block, action in next, table do
        locateItem(block)
    end
end

yLevel = 0

blockTable = {
    ["minecraft:spruce_log"] = mineTree,
    ["minecraft:oak_log"] = mineTree,
    ["minecraft:birch_log"] = mineTree,
    ["minecraft:jungle_log"] = mineTree,
    ["minecraft:acacia_log"] = mineTree,
    ["minecraft:dark_oak_log"] = mineTree,
    ["minecraft:bedrock"] = bedrockHandler,
    ["minecraft:sugar_cane"] = mineSugarCane,
    ["minecraft:stone"] = mineStone,
    ["minecraft:redstone_ore"] = mineOre,
    ["minecraft:iron_ore"] = mineOre,
    ["minecraft:diamond_ore"] = mineOre
}

oreTable = {}
for block, action in next, blockTable do
    if action == mineOre then
        oreTable[block] = action
    end
end

function copyCode()
    local diskPresent = disk.isPresent("down")
    if diskPresent then
        local filepath = disk.getMountPath("down").."/startup.lua"
        fs.copy(filepath, "startup.lua")
    end
end

--scanWithAction(blockTable, true)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()

local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

_G.AutoRebirth = true 

local function safeFormatDescription(text)
    if not text then return "" end
    return string.gsub(text, "[|;]", "")
end

local function getGameData()
    local currentCoins = "0"
    local equippedSlimes = {}

    pcall(function()
        local rootUI = player.PlayerGui:FindFirstChild("Root")
        if not rootUI then return end

        local coinFrame = rootUI:FindFirstChild("LeftSideBar") and rootUI.LeftSideBar.CounterStack:FindFirstChild("CoinCounter")
        if coinFrame then
            local targetLabel = coinFrame:FindFirstChild("TextLabel", true)
            if targetLabel then
                currentCoins = targetLabel.Text
            end
        end

        local container = rootUI:FindFirstChild("Inventory") 
            and rootUI.Inventory.PageInventoryContent.SlimesPage.EquippedSlimesFrame:FindFirstChild("Container")
            
        if container then
            for _, slot in pairs(container:GetChildren()) do
                local slimeButton = slot:FindFirstChild("SlimeButton")
                if slimeButton then
                    for _, item in pairs(slimeButton:GetDescendants()) do
                        if item:IsA("TextLabel") and item.Text ~= "" then
                            -- กรองเอาเฉพาะข้อความที่มีเครื่องหมาย "/" (โอกาสดรอป)
                            if string.find(item.Text, "/") then
                                table.insert(equippedSlimes, item.Text)
                            end
                        end
                    end
                end
            end
        end
    end)

    return currentCoins, equippedSlimes
end


task.spawn(function()
    while task.wait(10) do
        if not _G.AutoRebirth then break end
        
        pcall(function()
            local rootUI = player.PlayerGui:FindFirstChild("Root")
            if not rootUI then return end

  
            local rightSideBar = rootUI:FindFirstChild("RightSideBar")
            if rightSideBar then
                local rebirthBtn = rightSideBar.ButtonStack.RebirthButton.IconButton
                if rebirthBtn then
                    local isOpen = rebirthBtn.RebirthMeter.Visible 
                    
                    if not isOpen then
                        if getconnections then
                            for _, connection in pairs(getconnections(rebirthBtn.MouseButton1Click)) do
                                connection:Fire()
                            end
                            for _, connection in pairs(getconnections(rebirthBtn.Activated)) do
                                connection:Fire()
                            end
                        elseif firesignal then
                            firesignal(rebirthBtn.MouseButton1Click)
                            firesignal(rebirthBtn.Activated)
                        end
                        task.wait(1) 
                    end
                end
            end
            

            local rebirthCount = 0
            local rebirthMenu = rootUI:FindFirstChild("Rebirth")
            if rebirthMenu then
                local content = rebirthMenu:FindFirstChild("Content")
                local rebirthContent = content and content:FindFirstChild("RebirthContent")
                local footer = rebirthContent and rebirthContent:FindFirstChild("Footer")
                local rebirthCountFrame = footer and footer:FindFirstChild("RebirthCount")
                
                if rebirthCountFrame then
                    for _, child in ipairs(rebirthCountFrame:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            rebirthCount = tonumber(string.match(child.Text, "%d+")) or 0
                            break
                        end
                    end
                end
            end


            local coins, slimes = getGameData()
            
            print("🔄 Rebirth:", rebirthCount, "🪙 Coin:", coins, "🦠 Slimes Equipped:", #slimes)

    
            local json_strings = {
                Level = rebirthCount, 
                Money = coins,
                EquippedSlimes = slimes
            }
            local EncodeJson = HttpService:JSONEncode(json_strings)

    
            local all_slimes_str = (#slimes > 0) and table.concat(slimes, ", ") or "None"

     
            local raw_messages = string.format("🔄 Rebirth: %s , 💰 Coin: %s , 🦠 Slime: [%s]", 
                tostring(rebirthCount), 
                tostring(coins), 
                all_slimes_str
            )


            local safe_messages = safeFormatDescription(raw_messages)


            if _G.Horst_SetDescription then
                _G.Horst_SetDescription(safe_messages, EncodeJson)
            end

        end)
    end
end)
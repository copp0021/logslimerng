local player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

-- เปิดใช้งาน Auto Rebirth
_G.AutoRebirth = true 

-- =======================================================
-- 1. ฟังก์ชันสแกนและลบตัวอักษรต้องห้าม (| และ ;)
-- =======================================================
local function safeFormatDescription(text)
    if not text then return "" end
    return string.gsub(text, "[|;]", "")
end

-- =======================================================
-- 2. ฟังก์ชันสำหรับดึงข้อมูลเกมปัจจุบัน (Coins & Slimes)
-- =======================================================
local function getGameData()
    local currentCoins = "0"
    local equippedSlimes = {}

    pcall(function()
        local rootUI = player.PlayerGui:FindFirstChild("Root")
        if not rootUI then return end

        -- ดึงข้อมูล Coin
        local coinFrame = rootUI:FindFirstChild("LeftSideBar") and rootUI.LeftSideBar.CounterStack:FindFirstChild("CoinCounter")
        if coinFrame then
            local targetLabel = coinFrame:FindFirstChild("TextLabel", true)
            if targetLabel then
                currentCoins = targetLabel.Text
            end
        end

        -- ดึงข้อมูล Slimes ที่สวมใส่อยู่
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

-- =======================================================
-- 3. ลูปหลักสำหรับทำงาน Auto Rebirth และอัปเดตสถานะ Sheet
-- =======================================================
task.spawn(function()
    while task.wait(10) do
        if not _G.AutoRebirth then break end
        
        pcall(function()
            local rootUI = player.PlayerGui:FindFirstChild("Root")
            if not rootUI then return end

            -- --- [ ส่วนที่ 3.1: กด Rebirth อัตโนมัติ ] ---
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
            
            -- --- [ ส่วนที่ 3.2: อ่านค่า Rebirth ปัจจุบัน ] ---
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

            -- --- [ ส่วนที่ 3.3: ดึงข้อมูล Coin/Slime แล้วแพ็กส่งระบบ Horst ] ---
            local coins, slimes = getGameData()
            
            print("🔄 Rebirth:", rebirthCount, "🪙 Coin:", coins, "🦠 Slimes Equipped:", #slimes)

            -- 1. เตรียมข้อมูลสำหรับส่งเข้า Google Sheets (ผ่าน JSON)
            local json_strings = {
                Level = rebirthCount, 
                Money = coins,
                EquippedSlimes = slimes
            }
            local EncodeJson = HttpService:JSONEncode(json_strings)

            -- ทำการเชื่อมรายชื่อสไลม์ทุกตัวเข้าด้วยกัน แยกด้วยลูกน้ำ (เช่น "1/100, 1/500, 1/1000")
            local all_slimes_str = (#slimes > 0) and table.concat(slimes, ", ") or "None"

            -- 2. สร้างข้อความที่จะโชว์ในรีจอย (รวมสไลม์ทุกตัว)
            local raw_messages = string.format("🔄 Rebirth: %s , 💰 Coin: %s , 🦠 Slime: [%s]", 
                tostring(rebirthCount), 
                tostring(coins), 
                all_slimes_str
            )

            -- 3. นำข้อความไปกรองตัวอักษรต้องห้ามก่อนส่งเสมอ
            local safe_messages = safeFormatDescription(raw_messages)

            -- 4. ส่งข้อมูลเข้าฟังก์ชันหลัก
            if _G.Horst_SetDescription then
                _G.Horst_SetDescription(safe_messages, EncodeJson)
            end

        end)
    end
end)
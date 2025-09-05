local defaultFrame = DEFAULT_CHAT_FRAME
local defaultWrite = DEFAULT_CHAT_FRAME.AddMessage
local log = function(text, r, g, b, group, holdTime)
   defaultWrite(defaultFrame, tostring(text), r, g, b, group, holdTime)
end

local TDGConfig = {
   scale = 0.6,
   xOffset = -600,
   yOffset = -10,
   inactivityTime = 6,
   path = {
      bubble = "Interface\\AddOns\\VwowDpsGirl\\Textures\\bubble",
      girl1 = "Interface\\AddOns\\VwowDpsGirl\\Textures\\girl1",
      girl2 = "Interface\\AddOns\\VwowDpsGirl\\Textures\\girl2",
      girlz = "Interface\\AddOns\\VwowDpsGirl\\Textures\\girlz",
      girlb = "Interface\\AddOns\\VwowDpsGirl\\Textures\\girlb",
   },
   needsUpdate = false,
}

TDG_SavedConfig = TDG_SavedConfig or {}

local mode = "dmg"
local SLEEPING = " ZZZzz"
local TDGFrame = CreateFrame("Frame", "TDGFrame", UIParent)
-- local myGUID = nil
local stats = {
   heal = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0},
   dmg = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0}
}

local function resetStats()
   stats = {
      heal = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0},
      dmg = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0}
   }
end

local function getInactivitySeconds()
   return time() - stats[mode].epoch_last
end

local function isInactive()
   return getInactivitySeconds() > TDGConfig.inactivityTime
end

local function incStats(dmgType, amount)
   if not amount then
      return
   end

   local m = stats[dmgType]
   -- start of combat
   if m.epoch_first == 0 then
      m.epoch_first = time()
   end
   m.epoch_last = time()
   m.hits = m.hits + 1
   m.sum = m.sum + amount
   if amount > m.max then
      m.max = amount
   end
   if amount > m.min or m.min == 0 then
      m.min = amount
   end
end

local function getDps()
   local duration = max(stats[mode].epoch_last - stats[mode].epoch_first, 1)
   local dps = stats[mode].sum / duration

   -- if dps == 0 and isInactive() then
   if isInactive() then
      return SLEEPING
   end

   if dps > 1000 then
      return string.format("%.0f", dps/1000).."k"
   end

   return string.format("%.0f", dps)
end

local currentImage = 1

local function getTexture()
   local c = TDGConfig

   if getDps() == SLEEPING then
      return c.path.girlz
   end

   if math.random(0, 100) < 5 then
      return c.path.girlb
   end

   if currentImage == 1 then
      currentImage = 2
      return c.path.girl2
   else
      currentImage = 1
      return c.path.girl1
   end
end

local function getColor()
   if getDps() == SLEEPING then
      return {0, 0, 0}
   end
   if mode == "dmg" then
      return {1, 0, 0}
   else
      return {0, 1, 0}
   end
end

function showGirl()
   local c = TDGConfig

   -- bubble
   local myImageFrame2 = CreateFrame("Frame", nil, UIParent)
   myImageFrame2:SetWidth(c.scale * 256)
   myImageFrame2:SetHeight(c.scale * 256)
   myImageFrame2:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-80 + c.xOffset) * c.scale, (120 + c.yOffset) * c.scale)

   local myImageTexture2 = myImageFrame2:CreateTexture(nil, "ARTWORK")
   myImageTexture2:SetAllPoints(myImageFrame2)
   myImageTexture2:SetTexture(c.path.bubble)
   myImageTexture2:SetBlendMode("BLEND")
   myImageFrame2:Show()

   -- girl
   local myImageFrame1 = CreateFrame("Frame", "VwowDpsGirlFrame", UIParent)
   myImageFrame1:SetWidth(c.scale * 256)
   myImageFrame1:SetHeight(c.scale * 256)
   myImageFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", c.scale * c.xOffset, c.scale * c.yOffset)
   myImageFrame1:SetAlpha(1.0)
   myImageFrame1:SetScale(1.0)

   local myImageTexture1 = myImageFrame1:CreateTexture(nil, "ARTWORK")
   myImageTexture1:SetAllPoints(myImageFrame1)
   myImageTexture1:SetTexture(c.path.girl1)
   myImageTexture1:SetBlendMode("BLEND")
   myImageTexture1:Show()
   myImageFrame1:Show()

   -- text
   local f = CreateFrame("Frame", nil, UIParent)
   f:SetWidth(50)
   f:SetHeight(30)
   f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-175 + c.xOffset) * c.scale, (225 + c.yOffset) * c.scale)

   local fs = f:CreateFontString(nil, "OVERLAY")
   fs:SetFont("Fonts\\ARIALN.TTF", math.floor(c.scale * 32), nil) -- OUTLINE third arg if wanted
   fs:SetTextColor(0, 0, 0)
   fs:SetText("OOPS")
   fs:SetPoint("CENTER", f, "CENTER")
   -- fs:SetRotation(math.rad(18))

   local function updateImage()
      local texture = getTexture()
      local dps = getDps()

      if (c.needsUpdate) then
         myImageFrame2:SetWidth(c.scale * 256)
         myImageFrame2:SetHeight(c.scale * 256)
         myImageFrame1:SetWidth(c.scale * 256)
         myImageFrame1:SetHeight(c.scale * 256)
         myImageFrame2:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-80 + c.xOffset) * c.scale, (120 + c.yOffset) * c.scale)
         myImageFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", c.scale * c.xOffset, c.scale * c.yOffset)
         f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-175 + c.xOffset) * c.scale, (225 + c.yOffset) * c.scale)
         c.needsUpdate = false
      end

      myImageFrame2:Hide()
      myImageFrame1:Hide()
      myImageTexture1:SetTexture(texture)
      myImageFrame2:Show()
      myImageFrame1:Show()
      -- fs:SetTextColor(unpack(getColor()))
      fs:SetText(dps)

      if isInactive() then
         resetStats()
      end
   end

   myImageFrame1:Show()
   -- local timer = C_Timer.NewTicker(0.1, updateImage) -- true makes it repeat
   myImageFrame1.UpdateState = function(self)
      updateImage()
   end
   myImageFrame1:SetScript(
      "OnUpdate",
      function()
         if ( this.tick or 0.1) > GetTime() then return else this.tick = GetTime() + 0.1 end
         this:UpdateState()
   end)
end

local function loadConfig ()
   mode = TDG_SavedConfig.mode or "dmg"
   TDGConfig.xOffset = TDG_SavedConfig.xOffset or -600
   TDGConfig.yOffset = TDG_SavedConfig.yOffset or -10
   TDGConfig.scale = TDG_SavedConfig.scale or 0.6
end

local function saveConfig ()
   TDG_SavedConfig.mode = mode
   TDG_SavedConfig.xOffset = TDGConfig.xOffset
   TDG_SavedConfig.yOffset = TDGConfig.yOffset
   TDG_SavedConfig.scale = TDGConfig.scale
end

-- local function combatLogging()
--    log(getDps())
--    log(getTexture())
--    --print("combatLogging cb")
--    --print(CombatLogGetCurrentEventInfo())
-- end

function VwowDpsGirl_OnLoad()
   this:RegisterEvent("UNIT_NAME_UPDATE");
   this:RegisterEvent("PLAYER_ENTERING_WORLD");
   this:RegisterEvent("PLAYER_REGEN_DISABLED")
   this:RegisterEvent("PLAYER_REGEN_ENABLED")
   this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");
   this:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS");
   -- this:RegisterEvent("CHAT_MSG_SPELL_CRIT_SELF_DAMAGE");
   -- this:RegisterEvent("CHAT_MSG_SPELL_DAMAGE_OTHER");
end

local function parseDmg(s)
   local _, _, amt = string.find(s, ".* (%d+)")
   -- log(amt)
   incStats("dmg", tonumber(amt))
end

function VwowDpsGirl_OnEvent()
   if (event == "UNIT_NAME_UPDATE" and arg1 == "player") then
      --print(UnitName("player"))
   end
   if (event == "PLAYER_ENTERING_WORLD") then
      showGirl()
   end
   if (event == "PLAYER_REGEN_ENABLED") then
      -- Could use inactivity here if we wanted
   end
   if (event == "PLAYER_REGEN_DISABLED") then
      -- Could use activity here if we wanted
   end
   if (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
      -- Ability dmg
      -- "Your Bloodthirst hit X for 123."
      -- log(arg1)
      parseDmg(arg1)
   end
   if (event == "CHAT_MSG_COMBAT_SELF_HITS") then
      -- White dmg
      -- "You hit X for 123."
      -- "You hit X for 123 (glancing)."
      -- log(arg1)
      parseDmg(arg1)
   end
end

-- TDGFrame.UpdateState = function(self)
--    combatLogging()
-- end

-- TDGFrame:SetScript(
--    "OnUpdate",
--    function()
--       if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
--       this:UpdateState()
-- end)

-- TDGFrame:SetScript(
--    "OnEvent",
--    function(_, event, addonName, x, y, z)
--       print("VwowDpsGirl stuff here!")
--       print(_)
--       print(x)
--       print(y)
--       print(z)
--       print(addonName)
--       print(event)
--       if event == "ADDON_LOADED" then
--          -- local addonName = ...
--          if addonName == "VwowDpsGirl" then
--             -- mode = TDG_SavedConfig.mode or "dmg"
--             log("HERE WE GO - load config here!")
--             -- TDG_SavedConfig.xOffset = TDGConfig.xOffset
--             -- TDG_SavedConfig.yOffset = TDGConfig.yOffset
--             -- TDG_SavedConfig.scale = TDGConfig.scale
--          end

--       elseif event == "PLAYER_ENTERING_WORLD" then
--          -- myGUID = UnitGUID("player")
--          -- resetStats()
--          -- loadConfig()
--          log("PEW PEW PEW")
--          showGirl()

--       -- elseif event == "PLAYER_LOGOUT" then
--       --    saveConfig()

--       -- elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
--       --    local timestamp,
--       --       subEvent,
--       --       hideCaster,
--       --       sourceGUID,
--       --       sourceName,
--       --       sourceFlags,
--       --       sourceRaidFlags,
--       --       destGUID,
--       --       destName,
--       --       destFlags,
--       --       destRaidFlags,
--       --       spellID,
--       --       spellName,
--       --       spellSchool,
--       --       amount,
--       --       overkill,
--       --       school,
--       --       resisted,
--       --       blocked,
--       --       absorbed,
--       --       critical,
--       --       glancing,
--       --       crushing,
--       --       isOffHand = CombatLogGetCurrentEventInfo()

--       --    if sourceGUID ~= myGUID then
--       --       return
--       --    end

--       --    if (subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL") and amount and amount > 0 then
--       --       incStats("heal", amount)
--       --    elseif tonumber(amount) and amount > 0 then
--       --       incStats("dmg", amount)
--       --    elseif subEvent == "SWING_DAMAGE" and amount == nil and spellID and spellID > 0 then
--       --       incStats("dmg", spellID)
--       --    end
--       end
--    end
-- )

local commands = setmetatable({
   -- {
      ["ax"] = function(arg)
         print("Adjusting x")
         TDGConfig.xOffset = TDGConfig.xOffset + arg
         TDGConfig.needsUpdate = true
         saveConfig()
         print("X adjusted")
      end,

      ["ay"] = function(arg)
         print("Adjusting y")
         TDGConfig.yOffset = TDGConfig.yOffset + arg
         TDGConfig.needsUpdate = true
         saveConfig()
         print("Y adjusted")
      end,

      ["x"] = function(arg)
         print("Setting x")
         TDGConfig.xOffset = arg
         TDGConfig.needsUpdate = true
         saveConfig()
         print("X set")
      end,

      ["y"] = function(arg)
         print("Setting y")
         TDGConfig.yOffset = arg
         TDGConfig.needsUpdate = true
         saveConfig()
         print("Y set")
      end,

      ["s"] = function(arg)
         print("Setting scale")
         TDGConfig.scale = arg
         TDGConfig.needsUpdate = true
         saveConfig()
         print("Scaled")
      end,

      ["p"] = function(arg)
         print("Printing settings:")
         print("Scale: "..TDGConfig.scale)
         print("xOffset: "..TDGConfig.xOffset)
         print("yOffset: "..TDGConfig.yOffset)
      end,

      ["r"] = function(arg)
         print("Resetting customizations")
         TDGConfig.scale = 0.6
         TDGConfig.xOffset = -600
         TDGConfig.yOffset = -10
         TDGConfig.needsUpdate = true
         saveConfig()
         print("Reset")
      end,

      -- ["d"] = function(args)
      --    print("Enabling damage mode")
      --    mode = "dmg"
      -- end,

      -- ["h"] = function(args)
      --    print("Enabling heal mode")
      --    showGirl()
      --    -- mode = "heal"
      -- end,
   }, {
      __index = function()
         return function()
            -- local dmgChosen = " |cff00ff33(active)."
            -- local healChosen = "."
            -- if mode == "heal" then
            --    dmgChosen = "."
            --    healChosen = " |cff00ff33(active)."
            -- end
            log("|cffff33cc[DpsGirl]|cffff9999 - Small DPS calculator")
            log("Commands:")
            -- log("  |cffff66cc/dg d|cffffffff - Enable damage mode"..dmgChosen)
            -- log("  |cffff66cc/dg h|cffffffff - Enable heal mode"..healChosen)
            log("  |cffff66cc/dg x|cffffffff - Set X")
            log("  |cffff66cc/dg y|cffffffff - Set Y")
            log("  |cffff66cc/dg ax|cffffffff - Adjust X")
            log("  |cffff66cc/dg ay|cffffffff - Adjust Y")
            log("  |cffff66cc/dg s|cffffffff - Set scale")
            log("  |cffff66cc/dg p|cffffffff - Print settings")
            log("  |cffff66cc/dg r|cffffffff - Reset settings")
         end
      end
})

SLASH_TDG1 = "/dpsgirl"
SLASH_TDG2 = "/vwowdpsgirl"
SLASH_TDG3 = "/dg"
SLASH_TDG4 = "/vdg"
function SlashCmdList.TDG(args)
   if args then
      _, _, cmd, subargs = string.find(args, "^%s*(%S-)%s(.+)$")
      if not cmd then
         cmd = args
      end
      commands[string.lower(cmd)](subargs)
   else
      print("|cffff0000[DPSGIRL]: Unknown option|r")
   end
end

setfenv(1, pfUI:GetEnvironment())
local _, class = UnitClass("player")
if class ~= "SHAMAN" then return end

local btcFrame = CreateFrame("Frame")

btcFrame:RegisterEvent("VARIABLES_LOADED")
btcFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "VARIABLES_LOADED" then
    InitializeDefaultValues()
    AskToDisable()
    CreateGuiConfigEntries()
  end
end)

function InitializeDefaultValues()
  if pfUI_config then
    if pfUI_config.bettertotems == nil then
      pfUI_config.bettertotems = {}
    end
    local bt = pfUI_config.bettertotems

    if bt.asked == nil then
      pfUI:UpdateConfig("bettertotems", nil, "asked", 0)
    end
    if bt.recallRange == nil then
      pfUI:UpdateConfig("bettertotems", nil, "recallRange", 45)
    end
    if bt.recall == nil then
      pfUI:UpdateConfig("bettertotems", nil, "recall", "1")
    end
  end
end

function AskToDisable()
  if pfUI_config
     and pfUI_config.disabled
     and pfUI_config.disabled.totems == "0"
     and pfUI_config.bettertotems
     and pfUI_config.bettertotems.asked == 0 then
    CreateQuestionDialog(
        "The default pfUI totem module is enabled." .. "\n" ..
        "You don't need it if you're running Better Totems" .. "\n" ..
        "Do you want to disable it and reload?",
        { "Yes", function()
            pfUI_config.disabled.totems = "1"
            ReloadUI()
        end },
        { "No", function() end },
        nil)
    pfUI_config.bettertotems.asked = 1
  end
end

function CreateGuiConfigEntries()
  local CreateConfig = pfUI.gui.CreateConfig
  local CreateGUIEntry = pfUI.gui.CreateGUIEntry
  local U = pfUI.gui.UpdaterFunctions
  CreateGUIEntry(T["Thirdparty"], T["Better Totems"], function()
    CreateConfig(U["bettertotems"], T["Enable Recall Warning"], C.bettertotems, "recall", "checkbox")
    CreateConfig(U["bettertotems"], T["Recall Warning Range"], C.bettertotems, "recallRange", "text", nil, nil, nil, "number")
    CreateConfig(U["bettertotems"], T["Website"], nil, nil, "button", function()
      pfUI.chat.urlcopy.CopyText("https://github.com/Bombg/pfUI-bettertotems")
    end)
  end)
end

DoesTableContainKeyBT = function(table, contains)
  return table[contains] ~= nil
end

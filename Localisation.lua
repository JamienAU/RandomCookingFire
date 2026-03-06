local _, RCF = ...
RCF.Localisation = setmetatable({ }, {__index=function (t,k) return k end})
local L = RCF.Localisation
local locale = GetLocale()


-- enUS / enGB / Default
L = L or {}
L["ADDON_NAME"] = "Random Cooking Fire"
L["NO_VALID_CHOSEN"] = "|cff42E400Random Cooking Fire|r - No valid toy chosen. Setting macro to use Cooking Fire"
L["MACRO_NAME"] = "Random Hearth"
L["THANKS"] = "Thanks for using my addon"
L["DESCRIPTION"] = "Add or remove hearthstone toys from rotation"
L["SELECT_ALL"] = "Select all"
L["DESELECT_ALL"] = "Deselect all"
L["OPT_MACRO_ICON"] = "Macro icon"
L["SETUP_1"] = "Setting up Random Cooking Fire database."
L["RANDOM"] = "Random"
L["COOKINGFIRE"] = "Cooking Fire"
L["MACRO_NOT_FOUND"] = "|cff42E400Random Cooking Fire|r - Macro not found, creating macro named '"
L["UPDATE_MACRO_NAME"] = "|cff42E400Random Cooking Fire|r - Updating macro name to '"
L["UNIQUE_NAME_ERROR"] = "Macro name in use!\nPlease pick a unique name."
L["OPT_MACRO_NAME"] = "Macro name"

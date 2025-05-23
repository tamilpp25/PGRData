local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiGridCharacterCareer = require("XUi/XUiCharacter/XUiGridCharacterCareer")

local ipairs = ipairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiCharacterCarerrTips = XLuaUiManager.Register(XLuaUi, "UiCharacterCarerrTips")

function XUiCharacterCarerrTips:OnAwake()
    self.BtnClose.CallBack = function() self:Close() end
    self.GridCharacterCareer.gameObject:SetActiveEx(false)
end

function XUiCharacterCarerrTips:OnStart(characterId)
    self.CareerGrids = {}
    local careerIds = {}
    if XTool.IsNumberValid(characterId) then
        local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
        careerIds = XMVCA.XCharacter:GetCareerIdsByCharacterType(characterType)
    else
        careerIds = XMVCA.XCharacter:GetAllCharacterCareerIds()
    end
    for index, careerId in ipairs(careerIds) do
        local grid = self.CareerGrids[index]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridCharacterCareer, self.PanelLayout)
            grid = XUiGridCharacterCareer.New(go)
            self.CareerGrids[index] = grid        
        end
        grid:Refresh(careerId)
        grid.GameObject:SetActiveEx(true)
    end
end
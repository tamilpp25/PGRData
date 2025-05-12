local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTheatre3SettlementMemberCell = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementMemberCell")

---@class XUiTheatre3SettlementProficiency : XUiNode 成员精通
---@field Parent XUiTheatre3Settlement
---@field _Control XTheatre3Control
local XUiTheatre3SettlementProficiency = XClass(XUiNode, "XUiTheatre3SettlementProficiency")

function XUiTheatre3SettlementProficiency:OnStart()
    ---@type XUiTheatre3SettlementMemberCell[]
    self._CharacterList = {}
    self:Init()
end

function XUiTheatre3SettlementProficiency:Init()
    ---@type XUiGridCommon
    self._RewardGrid = XUiGridCommon.New(self.Parent, self.Grid256New)
    self._RewardGrid:SetProxyClickFunc(function()
        XLuaUiManager.Open("UiTheatre3Tips", XEnumConst.THEATRE3.Theatre3TalentPoint)
    end)
    self._Data = self._Control:GetSettleData()
end

function XUiTheatre3SettlementProficiency:UpdateMember()
    if #self._Data.BattleCharacters == 0 then
        self.ListCharacter.gameObject:SetActiveEx(false)
        return
    end

    self.ListCharacter.gameObject:SetActiveEx(true)
    for i, v in ipairs(self._Data.BattleCharacters) do
        local grid = self._CharacterList[i]
        if not grid then
            local go = i == 1 and self.CharacterGrid or XUiHelper.Instantiate(self.CharacterGrid, self.CharacterGrid.parent)
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, go)
            grid = XUiTheatre3SettlementMemberCell.New(uiObject.CharacterGrid, self)
            self._CharacterList[i] = grid
        end
        grid:SetData(v)
    end
end

function XUiTheatre3SettlementProficiency:StopCharacterExpAnim()
    for _, grid in pairs(self._CharacterList) do
        grid:StopExpAnim()
        grid:RefreshLv()
    end
end

function XUiTheatre3SettlementProficiency:PlayCharacterExpAnim()
    for _, grid in pairs(self._CharacterList) do
        grid:PlayExpAnim()
    end
end

function XUiTheatre3SettlementProficiency:OnEnable()
    local reward = XRewardManager.CreateRewardGoods(XEnumConst.THEATRE3.Theatre3TalentPoint, self._Data.StrengthPoint)
    self._RewardGrid:Refresh(reward)
    self:UpdateMember()
end

return XUiTheatre3SettlementProficiency
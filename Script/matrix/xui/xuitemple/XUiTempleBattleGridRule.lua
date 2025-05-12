local XUiTempleBattleRound = require("XUi/XUiTemple/XUiTempleBattleRound")
---@class XUiTempleBattleGridRule : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field PanelRound1 UnityEngine.RectTransform
---@field PanelRound2 UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field _Control XTempleControl
local XUiTempleBattleGridRule = XClass(XUiNode, "XUiTempleBattleGridRule")

function XUiTempleBattleGridRule:Ctor()
    self._Data = nil
    self._RuleOriginalColor = nil
end

--region 生命周期
function XUiTempleBattleGridRule:OnStart()
    self._PanelRoundUi = {}
    self._TIME_AMOUNT = 4
    for i = 1, self._TIME_AMOUNT do
        self._PanelRoundUi[i] = XUiTempleBattleRound.New(self["PanelRound" .. i], self)
    end

    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)

    self._RuleOriginalColor = self.TxtDetail.color
end

function XUiTempleBattleGridRule:OnRelease()
    XUiNode.OnRelease(self)
    self._RuleOriginalColor = nil
end

---@param data XTempleGameUiDataRule
function XUiTempleBattleGridRule:Update(data)
    -- 规则详情界面不存在此ui
    if self.PanelRulePrompt then
        if self._Data and data.IsActive then
            if data.Score > self._Data.Score then
                self.PanelRulePrompt.gameObject:SetActiveEx(false)
                self.PanelRulePrompt.gameObject:SetActiveEx(true)
            end
        end
    end

    self._Data = data
    self.Transform.name = data.UiName
    if self.TxtNum then
        self.TxtNum.text = data.Score
    end
    self.TxtName.text = data.Name
    for i = 1, self._TIME_AMOUNT do
        if data.Time[i] then
            self._PanelRoundUi[i]:Update(data.Time[i])
            self._PanelRoundUi[i]:Open()
        else
            self._PanelRoundUi[i]:Close()
        end
    end

    if self.ImgBgOn then
        self.ImgBgOn.gameObject:SetActiveEx(data.IsActive)
        self.ImgBgOff.gameObject:SetActiveEx(not data.IsActive)
    end
    if data.IsExpire then
        self.TxtDetail.text = XTool.RemoveRichText(data.Text)
        self.TxtDetail.supportRichText = false
        self.TxtDetail.color = XUiHelper.Hexcolor2Color("283233FF")
    else
        self.TxtDetail.text = data.Text
        self.TxtDetail.supportRichText = true
        self.TxtDetail.color = self._RuleOriginalColor
    end

    if self.ImgBg1 then
        self.ImgBg1:SetSprite(data.Bg)
    end
end

function XUiTempleBattleGridRule:OnClick()
    if not self._Control:IsEditor() then
        XLuaUiManager.Open("UiTempleAffixDetail")
    end
    if self._Data then
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_ON_CLICK_RULE, self._Data.Id)
    end
end

return XUiTempleBattleGridRule

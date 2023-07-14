local GridLoseTip = require("XUi/XUiSettleLose/XUiGridLoseTip")

---@class XUiDlcHuntPowerSettleLose:XLuaUi
local XUiDlcHuntPowerSettleLose = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPowerSettleLose")

function XUiDlcHuntPowerSettleLose:Ctor()
    self.SpecialSoundMap = {}
end

function XUiDlcHuntPowerSettleLose:OnAwake()
    self:RegisterClickEvent(self.BtnDlcBlue, self.OnClickQuitTeam)
    self:RegisterClickEvent(self.BtnDlcYellow, self.Close)
    self:RegisterClickEvent(self.BtnLose, self.Close)
end

---@param data XDlcHuntSettle
function XUiDlcHuntPowerSettleLose:OnStart(data)
    self.TxtPeople.text = CS.XTextManager.GetText("BattleLoseActorNum", #data.Members)
    self.TxtStageName.text = data.Name
    self:SetTips(data.SettleLoseTipId)
end

function XUiDlcHuntPowerSettleLose:OnClickQuitTeam()
    XDataCenter.DlcRoomManager.Quit()
    self:Close()
end

---
--- 根据"settleLoseTipId"来生成提示
function XUiDlcHuntPowerSettleLose:SetTips(settleLoseTipId)
    if not self.HadSetTip then
        local tipDescList = XFubenConfigs.GetTipDescList(settleLoseTipId)
        if tipDescList == nil then
            XLog.Error("XUiDlcHuntPowerSettleLose:SetTips函数错误，tipDescList为空")
            return
        end
        local skipIdList = XFubenConfigs.GetSkipIdList(settleLoseTipId)
        if tipDescList == nil then
            XLog.Error("XUiDlcHuntPowerSettleLose:SetTips函数错误，skipIdList为空")
            return
        end

        for i, desc in ipairs(tipDescList) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridLoseTip)
            obj.transform:SetParent(self.PanelTips.transform, false)
            obj.gameObject:SetActiveEx(true)
            GridLoseTip.New(obj, self, { ["TipDesc"] = desc, ["SkipId"] = skipIdList[i] })
        end
        self.GridLoseTip.gameObject:SetActiveEx(false)
        self.HadSetTip = true
    end
end

return XUiDlcHuntPowerSettleLose

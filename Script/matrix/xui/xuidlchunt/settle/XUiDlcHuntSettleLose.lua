---@class XUiDlcHuntSettleLose:XLuaUi
local XUiDlcHuntSettleLose = XLuaUiManager.Register(XLuaUi, "UiDlcHuntSettleLose")

function XUiDlcHuntSettleLose:Ctor()
    self.SpecialSoundMap = {}
end

function XUiDlcHuntSettleLose:OnAwake()
    self:RegisterClickEvent(self.BtnDlcBlue, self.OnClickQuitTeam)
    self:RegisterClickEvent(self.BtnDlcYellow, self.Close)
    self:RegisterClickEvent(self.BtnLose, self.Close)
end

---@param data XDlcHuntSettle
function XUiDlcHuntSettleLose:OnStart(data)
    self.TxtPeople.text = CS.XTextManager.GetText("BattleLoseActorNum", #data.Members)
    self.TxtStageName.text = data.Name
    self:SetTips(data:GetLoseTipBoss())
end

function XUiDlcHuntSettleLose:OnClickQuitTeam()
    XDataCenter.DlcRoomManager.Quit()
    self:Close()
end

---
--- 根据"settleLoseTipId"来生成提示
function XUiDlcHuntSettleLose:SetTips(tipDescList)
    if not self.HadSetTip then
        for i, desc in ipairs(tipDescList) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridLoseTip, self.GridLoseTip.transform.parent)
            obj.gameObject:SetActiveEx(true)
            local uiGrid = { Transform = obj.transform }
            XTool.InitUiObject(uiGrid)
            uiGrid.TxtTip.text = desc.Desc
            uiGrid.TxtTip1.text = desc.Name
        end
        self.GridLoseTip.gameObject:SetActiveEx(false)
        self.HadSetTip = true
    end
end

return XUiDlcHuntSettleLose

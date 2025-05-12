local XUiDlcSettlementBase = require("XUi/XUiDlcBase/XUiDlcSettlementBase")
local XUiDlcSettleLose = XLuaUiManager.Register(XUiDlcSettlementBase, "UiDlcSettleLose")
local GridLoseTip = require("XUi/XUiSettleLose/XUiGridLoseTip")

function XUiDlcSettleLose:OnAwake()
    self.BtnLose = self.Transform:Find("SafeAreaContentPane/PanelLose/BtnLose"):GetComponent("Button")
    
    if not self.BtnLose then
        self:Close()
        return
    end

    self:RegisterClickEvent(self.BtnLose, self._Close)
    self.GridLoseTip.gameObject:SetActiveEx(false)
    self._IsSetTip = false
    self._WorldId = nil
end

function XUiDlcSettleLose:OnStart()
    if not XMVCA.XDlcRoom:HasFightBeginData() then
        self.TxtPeople.text = ""
        self.TxtStageName.text = ""
        self.BtnRestart.gameObject:SetActiveEx(false)
        self.BtnTongRed.gameObject:SetActiveEx(false)
        self:_SetTips(0)
        return
    end

    local beginData = XMVCA.XDlcRoom:GetFightBeginData()
    local roomData = beginData:GetRoomData()
    local playerData = roomData:GetPlayerDataById(XPlayer.Id)
    local worldId = roomData:GetWorldId()
    local tipsId = XMVCA.XDlcWorld:GetSettleLoseTipIdById(worldId)

    self.TxtPeople.text = XUiHelper.GetText("BattleLoseActorNum", playerData and playerData:GetCharacterAmount() or 0)
    self.TxtStageName.text = XMVCA.XDlcWorld:GetWorldNameById(worldId)
    self.BtnRestart.gameObject:SetActiveEx(false)
    self.BtnTongRed.gameObject:SetActiveEx(false)
    self._WorldId = worldId
    self:_SetTips(tipsId)
end

---
--- 根据"settleLoseTipId"来生成提示
function XUiDlcSettleLose:_SetTips(settleLoseTipId)
    if not self._IsSetTip then
        local tipDescList = XFubenConfigs.GetTipDescList(settleLoseTipId)
        
        if tipDescList == nil then
            XLog.Error("XUiDlcSettleLose:SetTips函数错误，tipDescList为空")
            return
        end

        local skipIdList = XFubenConfigs.GetSkipIdList(settleLoseTipId)
        
        if skipIdList == nil then
            XLog.Error("XUiDlcSettleLose:SetTips函数错误，skipIdList为空")
            return
        end

        for i, desc in ipairs(tipDescList) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridLoseTip)
            
            obj.transform:SetParent(self.PanelTips.transform, false)
            obj.gameObject:SetActiveEx(true)
            GridLoseTip.New(obj, self, { ["TipDesc"] = desc, ["SkipId"] = skipIdList[i] })
        end
        
        self._IsSetTip = true
    end
end

function XUiDlcSettleLose:_Close()
    if self._WorldId then
        local agency = XMVCA.XDlcWorld:GetAgencyByWorldId(self._WorldId)

        if agency then
            if not agency:DlcCheckActivityInTime() then
                agency:DlcActivityTimeOutRunMain()
                return
            end
        end
    end

    self:Close()
end

return XUiDlcSettleLose
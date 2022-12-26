-- 兵法蓝图天赋详细页面
local XUiRpgTowerNature = XLuaUiManager.Register(XLuaUi, "UiRpgTowerNature")
local ItemIcon = require("XUi/XUiRpgTower/Common/XUiRpgTowerItemIcon")
function XUiRpgTowerNature:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:OnClose() end
    self.BtnActive.CallBack = function() self:OnClickActive() end
end

function XUiRpgTowerNature:OnStart(rTalent)
    self.RTalent = rTalent
    self:RefreshTalent()
end

function XUiRpgTowerNature:OnEnable()
    self:AddEventListener()
end

function XUiRpgTowerNature:OnDisable()
    self:RemoveEventListener()
end

function XUiRpgTowerNature:OnDestroy()
    self:RemoveEventListener()
end
--================
--增加Event监听
--================
function XUiRpgTowerNature:AddEventListener()
    if self.AddEvent == true then return end
    self.AddEvent = true
    XEventManager.AddEventListener(XEventId.EVENT_RPGTOWER_ON_TALENT_UNLOCK, self.OnUnLockSuccess, self)
end
--================
--移除Event监听
--================
function XUiRpgTowerNature:RemoveEventListener()
    if self.AddEvent == false then return end
    self.AddEvent = false
    XEventManager.RemoveEventListener(XEventId.EVENT_RPGTOWER_ON_TALENT_UNLOCK, self.OnUnLockSuccess, self)
end
--================
--天赋解锁成功时（回调）
--================
function XUiRpgTowerNature:OnUnLockSuccess()
    self:Close()
end
--================
--刷新面板内容控件
--================
function XUiRpgTowerNature:RefreshTalent()
    self.RImgSkill:SetRawImage(self.RTalent:GetIconPath())
    self.TxtCost.text = self.RTalent:GetCostStr()
    self.TxtName.text = self.RTalent:GetTalentName()
    self.TxtDesc.text = self.RTalent:GetDescription()
    local chara = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(self.RTalent:GetCharacterId())
    self.ItemIcon = ItemIcon.New(self.RImgTalentIcon, chara:GetTalentItem())
    if self.RTalent:GetIsUnLock() then
        self.TxtCost.gameObject:SetActiveEx(false)
        self.BtnActive:SetButtonState(CS.UiButtonState.Disable)
        self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerTalentActive"))
    elseif not self.RTalent:GetCanUnLock() then
            if not self.RTalent:CheckNeedTeamLevel() then
                self.TxtCost.gameObject:SetActiveEx(false)
                self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerTalentLock"))
            else
                self.TxtCost.gameObject:SetActiveEx(true)
                self.BtnActive:SetButtonState(CS.UiButtonState.Normal)
                self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerUnlockTalent"))
            end
    else
        self.TxtCost.gameObject:SetActiveEx(true)
        self.BtnActive:SetButtonState(CS.UiButtonState.Normal)
        self.BtnActive:SetName(CS.XTextManager.GetText("RpgTowerUnlockTalent"))
    end
end
--================
--点击激活按钮
--================
function XUiRpgTowerNature:OnClickActive()
    XDataCenter.RpgTowerManager.CharaTalentActive(self.RTalent)
end
--================
--点击关闭按钮
--================
function XUiRpgTowerNature:OnClose()
    self:Close()
end
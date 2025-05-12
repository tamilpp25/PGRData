-- 战斗扭蛋界面
---@class XUiFightLilithGacha : XLuaUi
---@field _Control XFightLilithGachaControl
local XUiFightLilithGacha = XLuaUiManager.Register(XLuaUi, "UiFightLilithGacha")
local XUiGridIcon = require("XUi/XUiFight/FightLilithGacha/XUiGridIcon")

function XUiFightLilithGacha:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnGacha, self.OnBtnGachaClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBigClick)
    self.GirdIcon.gameObject:SetActiveEx(false)
    self.AnimRoot = self.Transform:Find("Animation")
end

function XUiFightLilithGacha:OnStart()
    self.TotalCoin = 0
    self.UnlockIdDict = {}
    self.UnlockId = 0
    self.GroupId = 0
    self.IdList = {}
    self.GridPool = {}
    self.IsShowBtnGacha = true
end

function XUiFightLilithGacha:OnEnable()
    self.Panelcon.gameObject:SetActiveEx(false)
    self.PanelGapu.gameObject:SetActiveEx(false)
    self.BtnGacha.gameObject:SetActiveEx(true)
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System)
end

function XUiFightLilithGacha:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    XDataCenter.InputManagerPc.ResumeCurInputMap()
end

function XUiFightLilithGacha:Refresh()
    self.TxtCoin.text = self.TotalCoin
    self:RefreshGachaGrids()
end

function XUiFightLilithGacha:RefreshGachaGrids()
    local onCreate = function(item, id)
        item:Refresh(id, self.UnlockIdDict[self.GroupId] and self.UnlockIdDict[self.GroupId][id])
    end
    XUiHelper.CreateTemplates(self, self.GridPool, self.IdList, XUiGridIcon.New, self.GirdIcon, self.PanelItemList, onCreate)
end

function XUiFightLilithGacha:RefreshUnlockGacha()
    if self.UnlockId == 0 then
        self:Refresh()
        return
    end

    local leftIcon = self._Control._Model:GetGapuLeftIcon(self.UnlockId)
    local rightIcon = self._Control._Model:GetGapuRightIcon(self.UnlockId)
    self.RImgGapuLeft:SetRawImage(leftIcon)
    self.RImgGapuRight:SetRawImage(rightIcon)

    local gachaIcon = self._Control._Model:GetGachaIcon(self.UnlockId)
    self.RImgGachaIcon:SetRawImage(gachaIcon)
    self.RImgGachaIconBlack:SetRawImage(gachaIcon)
    
    self.PanelGapu.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("DrawPrize", handler(self, self.AnimaEndCallback), handler(self, self.AnimaBeginCallback))
end

function XUiFightLilithGacha:CheckBtnGachaShow()
    self.BtnGacha.gameObject:SetActiveEx(self.IsShowBtnGacha)
end

function XUiFightLilithGacha:AnimaBeginCallback()
    -- 抽到扭蛋后间隔一段时间才可继续扭蛋
    local intervalTime = self._Control._Model:GetIntervalTime(self.UnlockId)
    self.IsShowBtnGacha = false
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self.IsShowBtnGacha = true
        self:CheckBtnGachaShow()
        self.Timer = nil
    end, intervalTime * 1000)
end

function XUiFightLilithGacha:AnimaEndCallback()
    self:CheckBtnGachaShow()
    self:Refresh()
end

-- 设置数据
-- totalCoin：总代币数
-- unlockIdList：已解锁的扭蛋id列表
-- groupId：扭蛋组Id
function XUiFightLilithGacha:SetData(totalCoin, unlockIdList, groupId)
    self.TotalCoin = totalCoin
    self.GroupId = groupId
    self.IdList = self._Control._Model:GetIdList(groupId)
    if XTool.IsTableEmpty(self.IdList) then
        XLog.Error(string.format("组Id：%s对应的Id列表为空，请检查配置", groupId))
        return
    end
    
    local unlockIdDict = self.UnlockIdDict[groupId]
    if not unlockIdDict then
        unlockIdDict = {}
        self.UnlockIdDict[groupId] = unlockIdDict
    end
    -- 找出本次数据中解锁的id，播放动画
    self.UnlockId = 0
    local unlockId = 0
    for _, unlockIdFix in pairs(unlockIdList) do
        unlockId = FixToInt(unlockIdFix)
        if not unlockIdDict[unlockId] then
            self.UnlockId = unlockId
            unlockIdDict[unlockId] = true
        end
    end
    self:RefreshUnlockGacha()
end

function XUiFightLilithGacha:OnBtnTanchuangCloseBigClick()
    if self.AnimRoot then
        -- DrawPrize动画里控制Panelcon的显隐，会受其他动画影响导致其显隐不受代码控制
        self:StopAnimation("DrawPrize")
        self.AnimRoot.gameObject:SetActiveEx(false)
        self.AnimRoot.gameObject:SetActiveEx(true)
    end
    self.Panelcon.gameObject:SetActiveEx(false)
end

function XUiFightLilithGacha:OnBtnGachaClick()
    if self.TotalCoin == 0 then
        XUiManager.TipText("GachaCoinNotEnough")
        return
    end
    
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.Custom1Key, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.Custom1Key, CS.XOperationClickType.KeyUp)
    end
end

function XUiFightLilithGacha:Close()
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self.Super.Close(self)
end

return XUiFightLilithGacha
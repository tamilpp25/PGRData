--等级天赋说明弹窗
local XUiTRPGDialog = XLuaUiManager.Register(XLuaUi, "UiTRPGDialog")

function XUiTRPGDialog:OnAwake()
    XDataCenter.TRPGManager.CheckSaveIsAlreadyOpenPanelLevel()
    self:AutoAddListener()
end

function XUiTRPGDialog:OnStart()
    XEventManager.DispatchEvent(XEventId.EVENT_TRPG_OPEN_LEVEL_DIALOG)
end

function XUiTRPGDialog:OnEnable()

    local curLevel = XDataCenter.TRPGManager.GetExploreLevel()
    local isMaxLevel = XTRPGConfigs.IsMaxLevel(curLevel)
    --当前等级和天赋点
    self.TextNum1.text = curLevel
    self.TextTianfuNum1.text = XTRPGConfigs.GetMaxTalentPoint(curLevel)
    if isMaxLevel then
        self.Image.gameObject:SetActiveEx(false)
        self.PanelNextLv.gameObject:SetActiveEx(false)
    else
        --下一级等级和天赋点
        self.TextNum2.text = curLevel + 1
        self.TextTianfuNum2.text = XTRPGConfigs.GetMaxTalentPoint(curLevel + 1)
        self.Image.gameObject:SetActiveEx(true)
        self.PanelNextLv.gameObject:SetActiveEx(true)
    end
end

function XUiTRPGDialog:OnDisable()

end

function XUiTRPGDialog:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBigClick)
end

function XUiTRPGDialog:OnBtnTanchuangCloseBigClick()
    self:Close()
end
--风格技能详情界面，管理风格技能的激活和卸载
local XUiGuildBossSkillDetails = XLuaUiManager.Register(XLuaUi, "UiGuildBossSkillDetails")

function XUiGuildBossSkillDetails:OnAwake()
    self:AutoAddListener()
end

function XUiGuildBossSkillDetails:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnActive.CallBack = function () self:OnBtnActiveClick() end
    self.BtnUninstall.CallBack = function () self:OnBtnUninstallClick() end
end

function XUiGuildBossSkillDetails:RefreshInfo()
    -- 当前风格选择技能的个数
    local fightStyle = XDataCenter.GuildBossManager.GetFightStyle()
    local allSelectSkill = fightStyle.EffectedSkillId or {}
    local activeSkillNum = (self.Config.Style == fightStyle.StyleId) and #allSelectSkill or 0
    local styleMaxCount = self.AllStyleConfig[self.Config.Style].MaxCount
    self.IsMaxSkillActiveCount = activeSkillNum >= styleMaxCount -- 是否达到激活上限
    
    self.IsConflitCore = false -- 是否有核心技能冲突
    for _, skillId in pairs(allSelectSkill) do
        if XDataCenter.GuildBossManager.IsCoreStyleSkill(skillId) and XDataCenter.GuildBossManager.IsCoreStyleSkill(self.Config.Id) then
            self.IsConflitCore = true
            break
        end
    end

    self.RImgIcon:SetRawImage(self.Config.Icon)
    self.TxtName.text = self.Config.Name
    self.TxtDesc.text = string.gsub(self.Config.Desc, "\\n", "\n")

    self.BgTagActive.gameObject:SetActiveEx(self.IsActive)
    self.BtnUninstall.gameObject:SetActiveEx(self.IsActive and not self.IsPermanent) -- 常驻技能不显示任何可操作按钮
    self.BtnActive.gameObject:SetActiveEx(not self.IsActive and not self.IsPermanent)

    self.BgTagFix.gameObject:SetActiveEx(self.IsPermanent) -- 常驻标签
    
    self.Lock.gameObject:SetActiveEx(self.IsLock)
    self.Txtlock.gameObject:SetActiveEx(self.IsLock)
    if self.IsLock then
        self.BtnActive:SetDisable(true)
        self.Txtlock.text = CSXTextManagerGetText("GuildBossStyleSkillLock", self.Config.UnlockLv)
        -- self.BtnActive:SetName(CSXTextManagerGetText("GuildBossStyleSkillLock", self.Config.UnlockLv))
    end

    if not self.IsSelect then
        self.BtnActive:SetDisable(true)
        self.BtnActive:SetName(CSXTextManagerGetText("GuildBossStyleSelect"))
    end
end

function XUiGuildBossSkillDetails:OnStart(styleSkillConfig, isActive, isLock, isSelect)
    self.AllStyleConfig = XGuildBossConfig.GetGuildBossFightStyle() -- 所有的风格数据
    self.Config = styleSkillConfig
    self.IsActive = isActive
    self.IsLock = isLock
    self.IsSelect = isSelect
    self.IsPermanent = styleSkillConfig.IsPermanent and styleSkillConfig.IsPermanent > 0

    self:RefreshInfo()
end

function XUiGuildBossSkillDetails:OnBtnActiveClick()
    if self.IsLock or not self.IsSelect then return end
    if self.IsMaxSkillActiveCount then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSkillMax"))
        return
    end

    if self.IsConflitCore then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSkillHasActiveCore"))
        return
    end

    -- 向服务器请求激活技能
    XDataCenter.GuildBossManager.GuildBossStyleSkillChangeRequeset(GuildBossStyleSkillChangeType.Active, self.Config.Id, function ()
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSkillActiveSuccess"))
        self.IsActive = true
        XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
            self:RefreshInfo()
        end)
    end)
end

function XUiGuildBossSkillDetails:OnEnable()

end

function XUiGuildBossSkillDetails:OnDestroy()

end

function XUiGuildBossSkillDetails:OnBtnUninstallClick()
    if not self.IsActive then return end
    -- 向服务器请求卸载技能
    XDataCenter.GuildBossManager.GuildBossStyleSkillChangeRequeset(GuildBossStyleSkillChangeType.Unistall, self.Config.Id, function ()
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSkillUninstallSuccess"))
        self.IsActive = false
        XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
            self:RefreshInfo()
        end)
    end)
end

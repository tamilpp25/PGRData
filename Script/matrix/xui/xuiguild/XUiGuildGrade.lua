
local GuildBuildIntervalWhenMaxLevel = CS.XGame.Config:GetInt("GuildBuildIntervalWhenMaxLevel")
local XUiGuildGrade = XLuaUiManager.Register(XLuaUi, "UiGuildGrade")

local ExpProgressAnimTime = 1

function XUiGuildGrade:OnAwake()
    self:InitCb()
end 

function XUiGuildGrade:OnStart()
    self:InitView()
end

function XUiGuildGrade:InitCb()
    self.BtnTanchuangClose.CallBack = function() 
        self:Close()
    end
    self:RegisterClickEvent(self.BtnCopy, self.OnBtnCopyClick)
end

function XUiGuildGrade:InitView()
    self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
    self.TxtPlayerIdNum.text = string.format("%08d", XDataCenter.GuildManager.GetGuildId())
    self.StandIcon:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    
    local level = XDataCenter.GuildManager.GetGuildLevel()
    local isMaxLevel = XDataCenter.GuildManager.IsGuildLevelMax(level)
    self.PanelExp.gameObject:SetActiveEx(not isMaxLevel)
    self.PanelGloryExp.gameObject:SetActiveEx(isMaxLevel)
    self.PanelCondition.gameObject:SetActiveEx(not isMaxLevel)
    self.PanelHighest.gameObject:SetActiveEx(isMaxLevel)
    if isMaxLevel then
        self:RefreshGloryExp(level)
    else
        self:RefreshExp(level)
    end
end 

function XUiGuildGrade:RefreshExp(level)
    self.TxtLevelNum.text = level
    local curBuild = XDataCenter.GuildManager.GetBuild()
    local guildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(level)
    self.TxtExpNum.text = string.format("<color=#008FFF>%s</color>/%s", tostring(curBuild), tostring(guildLevelTemplate.Build))

    self.TxtCurCapacity.text = guildLevelTemplate.Capacity
    local nextLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(level + 1)
    self.TxtNextCapacity.text = nextLevelTemplate.Capacity
    self.TxtTalentPoint.text = nextLevelTemplate.TalentPoint
    self:RefreshTalent(level + 1)

    local amount = XDataCenter.GuildManager.GetGuildExpAmount()
    self.ImgExpCircle.fillAmount = amount
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(ExpProgressAnimTime, function(delta)
        self.ImgExpCircleFill1.fillAmount = delta * amount
    end, function()
        self.ImgExpCircleFill1.fillAmount = amount
        XLuaUiManager.SetMask(false)
    end)
end

function XUiGuildGrade:RefreshGloryExp()
    local curBuild = XDataCenter.GuildManager.GetBuild()
    self.TxtGloryLevelNum.text = XDataCenter.GuildManager.GetGloryLevel()
    self.TextGloryLevelInfo.gameObject:SetActiveEx(false)
    self.TxtGloryExpNum.text = string.format("<color=#0e70bd><size=47>%s</size></color>/%s", tostring(curBuild), tostring(GuildBuildIntervalWhenMaxLevel))
end

function XUiGuildGrade:RefreshTalent(level)
    local talents = XGuildConfig.GetGuildTalentsByLevel(level)
    self:RefreshTemplateGrids(self.GridTalent, talents, self.PanelTalent, nil, "GridTalent", function(grid, talent)
        --移除 信标· 文本
        grid.TxtTalentName.text = string.sub(talent.Name, 9)
        local talentConfig = XGuildConfig.GetGuildTalentConfigById(talent.Id)
        grid.RImgSkillIconNormal:SetRawImage(talentConfig.TalentIcon)
    end)
end

function XUiGuildGrade:OnBtnCopyClick()
    XTool.CopyToClipboard(self.TxtPlayerIdNum.text)
end 
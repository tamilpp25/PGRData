local XUiGuildGloryLevel = XLuaUiManager.Register(XLuaUi, "UiGuildGloryLevel")
local XUiGridTalentListItem = require("XUi/XUiGuild/XUiChildItem/XUiGridTalentListItem")

local ShowGuildTalentHelp = "ShowGuildTalentHelp"

function XUiGuildGloryLevel:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildTalentHelp")
    self.BtnViewTalent.CallBack = function() self:OnBtnViewTalentClick() end
    self.TalentPointList = {}
    self:SetGuildInfo()
end

function XUiGuildGloryLevel:OnDestroy()
end

function XUiGuildGloryLevel:OnStart()    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTalent)
    self.DynamicTable:SetProxy(XUiGridTalentListItem)
    self.DynamicTable:SetDelegate(self)
    self.TalentPoints = XGuildConfig.GetSortedTalentPoints()    
    self.DynamicTable:SetDataSource(self.TalentPoints)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiGuildGloryLevel:SetGuildInfo()
    local pointTotal = XDataCenter.GuildManager.GetTalentPointFromBuild()
    local pointLevelNeed = CS.XGame.Config:GetInt("GuildGloryPointsPerLevel")
    local gloryLevel = XDataCenter.GuildManager.GetGloryLevel()
    local pointOwn = pointTotal % pointLevelNeed
    local pointNeed = pointLevelNeed - pointOwn
    -- self.ImgProgress.fillAmount = pointOwn / pointLevelNeed
    -- self.TxtTalentPoint.text = CS.XTextManager.GetText("GuildTalentPointProgress", pointOwn, pointNeed)
    self.TxtGloryLevel.text = gloryLevel
    self.TxtGloryDescription.text = CS.XTextManager.GetText("GuildTalentGloryDescription")

    -- 暂时隐藏
    self.ImgProgress.gameObject:SetActiveEx(false)
    self.TxtTalentPoint.gameObject:SetActiveEx(false)
    self.PanelLine.gameObject:SetActiveEx(false)
end

function XUiGuildGloryLevel:Refresh(bReload)
    self:UpdateDynamicTable(bReload)
end

--设置动态列表
function XUiGuildGloryLevel:UpdateDynamicTable(bReload)
    --刷新数据
    self.DynamicTable:ReloadDataASync(bReload and 1 or -1) 
end

--动态列表事件
function XUiGuildGloryLevel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TalentPoints[index]
        grid:Refresh(data)
    end
end

function XUiGuildGloryLevel:OnBtnBackClick()
    self:Close()
end

function XUiGuildGloryLevel:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildGloryLevel:OnBtnViewTalentClick()
    XDataCenter.GuildManager.GuildTalentListReq(function()
        XLuaUiManager.Open("UiGuildSkill")
    end)
end
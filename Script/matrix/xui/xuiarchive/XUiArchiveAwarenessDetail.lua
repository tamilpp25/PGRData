
--
-- Author: wujie
-- Note: 图鉴武器详情界面

local XUiArchiveAwarenessDetail = XLuaUiManager.Register(XLuaUi, "UiArchiveAwarenessDetail")

local XUiGridArchiveAwarenessDetail = require("XUi/XUiArchive/XUiGridArchiveAwarenessDetail")
local XUiGridArchiveEquipSetting = require("XUi/XUiArchive/XUiGridArchiveEquipSetting")

local FirstIndex = 1

function XUiArchiveAwarenessDetail:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.IsSettingOpen = false
    self:InitGridSites()
    self.TxtSkillDescList = {
        self.TxtSkillDes1,
        self.TxtSkillDes2,
        self.TxtSkillDes3,
    }

    self.GridSettingList = {
        XUiGridArchiveEquipSetting.New(self.GridSetting1,self),
        XUiGridArchiveEquipSetting.New(self.GridSetting2,self),
    }

    self.GridStoryList = {
        XUiGridArchiveEquipSetting.New(self.GridStory1,self),
        XUiGridArchiveEquipSetting.New(self.GridStory2,self),
        XUiGridArchiveEquipSetting.New(self.GridStory3,self),
        XUiGridArchiveEquipSetting.New(self.GridStory4,self),
        XUiGridArchiveEquipSetting.New(self.GridStory5,self),
    }

    self:AutoAddListener()
end

function XUiArchiveAwarenessDetail:OnStart(suitIdList,index)
    self:InitScene3DRoot()
    self:Init(suitIdList,index)
end

function XUiArchiveAwarenessDetail:Init(suitIdList,index)
    local suitId = suitIdList and suitIdList[index]
    if not suitId then
        return
    end
    self.SuitId = suitId
    self.SuitIdList = suitIdList
    self.SuitIdIndex = index

    self:UpdateSpecialIcon()
    self:UpdateSites()
    self:UpdateSetting()
    self:CheckNextMonsterAndPreMonster()

    self.SelectSiteIndex = nil
    if not XTool.IsTableEmpty(self.GridSiteList) then
        for _,grid in pairs(self.GridSiteList) do
            grid:ShowSelect(false)
        end
    end

    if #self.TemplateIdList > 1 then
        local firstSiteIndex = 1
        self:OnBtnGroupClick(firstSiteIndex)
    end
end

function XUiArchiveAwarenessDetail:OnDestroy()
    self.Scene3DRoot.PanelWeaponPlane.gameObject:SetActiveEx(true)
end

function XUiArchiveAwarenessDetail:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnNext.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnLast.CallBack = function()
        self:OnBtnLastClick()
    end
end

function XUiArchiveAwarenessDetail:InitGridSites()
    self.GridSiteList = {
        XUiGridArchiveAwarenessDetail.New(self.GridSite1,self),
        XUiGridArchiveAwarenessDetail.New(self.GridSite2,self),
        XUiGridArchiveAwarenessDetail.New(self.GridSite3,self),
        XUiGridArchiveAwarenessDetail.New(self.GridSite4,self),
        XUiGridArchiveAwarenessDetail.New(self.GridSite5,self),
        XUiGridArchiveAwarenessDetail.New(self.GridSite6,self),
    }
    for i, grid in ipairs(self.GridSiteList) do
        grid:SetClickCallback(function() self:OnBtnGroupClick(i) end)
    end
end

function XUiArchiveAwarenessDetail:InitScene3DRoot()
    if self.Scene3DRoot then return end
    self.Scene3DRoot = {}
    local root = self.Scene3DRoot
    local sceneRoot = self.UiSceneInfo.Transform
    root.Transform = sceneRoot
    root.PanelWeapon = self.UiModelGo:FindTransform("PanelWeapon"):GetComponent(typeof(CS.XAutoRotation))
    root.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    root.PanelWeaponPlane.gameObject:SetActiveEx(false)
end

function XUiArchiveAwarenessDetail:UpdateSpecialIcon()
    local iconPath = self._Control:GetAwarenessSuitInfoIconPath(self.SuitId)
    if iconPath then
        self.ImgSpecialIcon.gameObject:SetActiveEx(true)
        self:SetUiSprite(self.ImgSpecialIcon, iconPath)
    else
        self.ImgSpecialIcon.gameObject:SetActiveEx(false)
    end
end

function XUiArchiveAwarenessDetail:UpdateSites()
    local templateIdList = XEquipConfig.GetEquipTemplateIdsListBySuitId(self.SuitId)
    table.sort(templateIdList, function(aId, bId)
            local aSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(aId)
            local bSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(bId)
            return aSite < bSite
        end)

    self.TemplateIdList = templateIdList
    local siteCount = #templateIdList
    local templateId
    local site
    local isGet
    for i, grid in ipairs(self.GridSiteList) do
        if i > siteCount then
            grid.GameObject:SetActiveEx(false)
        else
            grid.GameObject:SetActiveEx(true)

            templateId = templateIdList[i]
            site = XDataCenter.EquipManager.GetEquipSiteByTemplateId(templateId)
            isGet = XMVCA.XArchive:IsAwarenessGet(templateId)
            grid:SetName(XEquipConfig.AwarenessSiteToStr[site])
            grid:SetGet(isGet)
        end
    end
end

function XUiArchiveAwarenessDetail:UpdateAwareness()
    local imgPath = XDataCenter.EquipManager.GetEquipLiHuiPath(self.SelectedTemplateId, 0)
    if imgPath then
        self.RImgAwareness:SetRawImage(imgPath)
        self.PlayableDirectorLoop:Stop()
        self:PlayAnimation("LihuiEnable", function() self.PlayableDirectorLoop:Play() end)
    end

    local site = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.SelectedTemplateId)
    self:SetUiSprite(self.ImgSiteBg, self._Control:GetStarToQualityName(site))
end

function XUiArchiveAwarenessDetail:UpdateResume()
    local templateId = self.SelectedTemplateId
    local awarenessName = XDataCenter.EquipManager.GetEquipName(templateId)
    self.TxtAwarenessName.text = awarenessName
    local site = XDataCenter.EquipManager.GetEquipSiteByTemplateId(templateId)
    self.TxtAwarenessSite.text = XEquipConfig.AwarenessSiteToStr[site]
    self.TxtAwarenessPainter.text = XDataCenter.EquipManager.GetEquipPainterName(templateId)
    self.TxtAwarenessMaxLv.text = XDataCenter.EquipManager.GetEquipMaxLevel(templateId)
    self.TxtAwarenessMaxBreakthrough.text = XDataCenter.EquipManager.GetEquipMaxBreakthrough(templateId)
end

function XUiArchiveAwarenessDetail:UpdateSetting()
    local suitId = self.SuitId
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, {XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS_SETTING_RED}, suitId)
    if XMVCA.XArchive:IsNewAwarenessSuit(suitId) then
        XMVCA.XArchive:RequestUnlockAwarenessSuit({suitId})
    end

    local newSettingIdList = self._Control:GetNewAwarenessSettingIdList(suitId)
    if newSettingIdList and #newSettingIdList > 0 then
        XMVCA.XArchive:RequestUnlockAwarenessSetting(newSettingIdList)
    end

    local settingDataList = XMVCA.XArchive:GetAwarenessSettingList(suitId)
    local settingType
    local showedSettingCount = 0
    local showedStoryCount = 0
    local grid
    for _, settingData in ipairs(settingDataList) do
        settingType = settingData.Type
        if settingType == XEnumConst.Archive.SettingType.Setting then
            showedSettingCount = showedSettingCount + 1
            grid = self.GridSettingList[showedSettingCount]
            if grid then
                grid:Refresh(XEnumConst.Archive.SubSystemType.Awareness, settingData)
                grid.GameObject:SetActiveEx(true)
            else
                XLog.Error("there is not enough grid in the awareness setting, suitId is " .. suitId .. ", settingid is " .. settingData.Id .. ", check then awareness setting table")
            end
        elseif settingType == XEnumConst.Archive.SettingType.Story then
            showedStoryCount = showedStoryCount + 1
            grid = self.GridStoryList[showedStoryCount]
            if grid then
                grid:Refresh(XEnumConst.Archive.SubSystemType.Awareness, settingData)
                grid.GameObject:SetActiveEx(true)
            else
                XLog.Error("there is not enough grid in the awareness story, suitid is " .. suitId .. ", settingid is " .. settingData.Id .. ", check then awareness setting table")
            end
        end
    end

    if showedSettingCount == 0 then
        self.PanelSetting.gameObject:SetActiveEx(false)
    else
        self.PanelSetting.gameObject:SetActiveEx(true)
        for i = showedSettingCount+1, #self.GridSettingList do
            self.GridSettingList[i].GameObject:SetActiveEx(false)
        end
    end

    if showedStoryCount == 0 then
        self.PanelStory.gameObject:SetActiveEx(false)
    else
        self.PanelStory.gameObject:SetActiveEx(true)
        for i = showedStoryCount+1, #self.GridStoryList do
            self.GridStoryList[i].GameObject:SetActiveEx(false)
        end
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelSettingContent)
end

function XUiArchiveAwarenessDetail:UpdateSkill()
    local skillDesList = XDataCenter.EquipManager.GetSuitSkillDesList(self.SuitId)

    local isHaveSkill = false
    for _, skillDes in pairs(skillDesList) do
        if skillDes then
            isHaveSkill = true
            break
        end
    end

    if isHaveSkill then
        local txtSkillDesc
        for i = 1, XEquipConfig.MAX_SUIT_SKILL_COUNT do
            txtSkillDesc = self.TxtSkillDescList[i]
            if skillDesList[i * 2] then
                txtSkillDesc.text = skillDesList[i * 2]
                txtSkillDesc.gameObject:SetActiveEx(true)
            else
                txtSkillDesc.gameObject:SetActiveEx(false)
            end
        end
        self.PanelNoSkill.gameObject:SetActiveEx(false)
        self.PanelSkill.gameObject:SetActiveEx(true)
    else
        self.PanelNoSkill.gameObject:SetActiveEx(true)
        self.PanelSkill.gameObject:SetActiveEx(false)
    end
end

function XUiArchiveAwarenessDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    self:Init(self.SuitIdList,self.NextIndex)
end

function XUiArchiveAwarenessDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    self:Init(self.SuitIdList,self.PreviousIndex)
end

function XUiArchiveAwarenessDetail:CheckNextMonsterAndPreMonster()
    self.NextIndex = self:CheckIndex(self.SuitIdIndex + 1)
    self.PreviousIndex = self:CheckIndex(self.SuitIdIndex - 1)

    if self.NextIndex == 0 then
        self.NextIndex = self:CheckIndex(FirstIndex)
    end

    if self.PreviousIndex == 0 then
        self.PreviousIndex = self:CheckIndex(#self.SuitIdList)
    end
end

function XUiArchiveAwarenessDetail:CheckIndex(index)
    return self.SuitIdList[index] and index or 0
end

-----------------------------------事件相关----------------------------------------->>>
function XUiArchiveAwarenessDetail:OnBtnGroupClick(index)
    if self.SelectSiteIndex == index then return end
    if not self.TemplateIdList or not self.TemplateIdList[index] then return end

    if self.SelectSiteIndex then
        self.GridSiteList[self.SelectSiteIndex]:ShowSelect(false)
    end
    self.GridSiteList[index]:ShowSelect(true)
    self.SelectSiteIndex = index

    self.SelectedTemplateId = self.TemplateIdList[index]
    self:UpdateAwareness()
    self:UpdateResume()
    self:UpdateSkill()
end

function XUiArchiveAwarenessDetail:OnCheckRedPoint(count)
    if count < 0 then
        self.PanelSettingRedPoint.gameObject:SetActiveEx(false)
        self.PanelStoryRedPoint.gameObject:SetActiveEx(false)
    else
        local newSettingIdList = self._Control:GetNewAwarenessSettingIdList(self.SuitId)
        if newSettingIdList then
            local type
            local isShowSettingReddot = false
            local isShowStoryReddot = false
            for _, id in ipairs(newSettingIdList) do
                type = self._Control:GetAwarenessSettingType(id)
                if type == XEnumConst.Archive.SettingType.Setting then
                    isShowSettingReddot = true
                elseif type == XEnumConst.Archive.SettingType.Story then
                    isShowStoryReddot = true
                end
            end
            self.PanelSettingRedPoint.gameObject:SetActiveEx(isShowSettingReddot)
            self.PanelStoryRedPoint.gameObject:SetActiveEx(isShowStoryReddot)
        else
            self.PanelSettingRedPoint.gameObject:SetActiveEx(false)
            self.PanelStoryRedPoint.gameObject:SetActiveEx(false)
        end
    end
end
-----------------------------------事件相关-----------------------------------------<<<
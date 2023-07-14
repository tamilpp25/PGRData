--
-- Author: wujie
-- Note: 图鉴意识一级界面的格子
local XUiGridArchiveAwareness = XClass(nil, "XUiGridArchiveAwareness")

function XUiGridArchiveAwareness:Ctor(ui, clickCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb

    XTool.InitUiObject(self)

    self.ImgGirdStarList = {
        self.ImgGirdStar1,
        self.ImgGirdStar2,
        self.ImgGirdStar3,
        self.ImgGirdStar4,
        self.ImgGirdStar5,
        self.ImgGirdStar6,
    }

    self.BtnClick.CallBack = function() self:OnBtnClick() end
end

function XUiGridArchiveAwareness:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridArchiveAwareness:SetClickCallback(callback)
    self.ClickCb = callback
end

function XUiGridArchiveAwareness:UpdateStar()
    local star = XDataCenter.EquipManager.GetSuitStar(self.SuitId)
    for i = 1, XEquipConfig.MAX_STAR_COUNT do
        if self.ImgGirdStarList[i] then
            self.ImgGirdStarList[i].gameObject:SetActiveEx(i <= star)
        end
    end
end

function XUiGridArchiveAwareness:UpdateCollectedCount()
    local suitId = self.SuitId
    local templateIdList = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
    local sumCount = #templateIdList
    local curCount = XDataCenter.ArchiveManager.GetAwarenessCountBySuitId(suitId)
    self.TxtSumCount.text = sumCount
    self.TxtCurCount.text = curCount
end

function XUiGridArchiveAwareness:Refresh(dataList,index)
    local data = dataList and dataList[index]
    if not data then
        return
    end
    self.Data = data
    local suitId = data.Id
    self.SuitId = suitId
    self.SuitIdList = {}

    for dataIndex,tmpData in pairs(dataList) do
        self.SuitIdList[dataIndex] = tmpData.Id
    end

    self.DataIndex = index

    local isBigIcon = true
    if self.RImgIcon then
        if XEquipConfig.IsDefaultSuitId(suitId) then
            self.RImgIcon.gameObject:SetActiveEx(false)
        else
            local icon
            if isBigIcon then
                icon = XDataCenter.EquipManager.GetSuitBigIconBagPath(suitId)
            else
                icon = XDataCenter.EquipManager.GetSuitIconBagPath(suitId)
            end

            self.RImgIcon:SetRawImage(icon)
            self.RImgIcon.gameObject:SetActiveEx(true)
        end
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi:SetUiSprite(self.ImgEquipQuality, XDataCenter.EquipManager.GetSuitQualityIcon(suitId))
    end

    if self.TxtName then
        self.TxtName.text = XDataCenter.EquipManager.GetSuitName(suitId)
    end

    if self.Data.Add and #self.Data.Add > 0 then
        self.TxtActivity.text = self.Data.Add
        self.TxtActivity.gameObject:SetActiveEx(true)
    else
        self.TxtActivity.gameObject:SetActiveEx(false)
    end


    self:UpdateStar()
    self:UpdateCollectedCount()
    XRedPointManager.CheckOnce(
        self.OnCheckRedPoint,
        self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS_GRID_NEW_TAG, XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS_SETTING_RED },
        self.SuitId
    )
end

-----------------------------------事件相关----------------------------------------->>>
function XUiGridArchiveAwareness:OnBtnClick()
    if self.ClickCb then
        self.ClickCb(self.SuitIdList,self.DataIndex, self)
    end
end

-- 有new标签时显示new标签，如果只有红点显示红点，红点和new标签同时存在则只显示new标签
function XUiGridArchiveAwareness:OnCheckRedPoint(count)
    local suitId = self.SuitId
    if count < 0 or not suitId then
        self.PanelNewTag.gameObject:SetActiveEx(false)
        self.PanelRedPoint.gameObject:SetActiveEx(false)
    else
        local isShowTag = XDataCenter.ArchiveManager.IsNewAwarenessSuit(suitId)
        if isShowTag then
            self.PanelNewTag.gameObject:SetActiveEx(true)
            self.PanelRedPoint.gameObject:SetActiveEx(false)
        else
            self.PanelNewTag.gameObject:SetActiveEx(false)
            self.PanelRedPoint.gameObject:SetActiveEx(XDataCenter.ArchiveManager.IsNewAwarenessSetting(suitId))
        end
    end
end
-----------------------------------事件相关-----------------------------------------<<<
return XUiGridArchiveAwareness
local XUiGridScoreTowerStage = require("XUi/XUiScoreTower/Storey/XUiGridScoreTowerStage")
local XUiCommonRollingNumber = require("XUi/XUiCommon/XUiCommonRollingNumber")
---@class XUiGridScoreTowerStageNormal : XUiGridScoreTowerStage
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerStageNormal = XClass(XUiGridScoreTowerStage, "XUiGridScoreTowerStageNormal")

function XUiGridScoreTowerStageNormal:OnStart()
    self.Super.OnStart(self)
    self.CurPlugPoint = 0
    self.MaxPlugPoint = 0
    ---@type XUiCommonRollingNumber
    self.RollingNumber = false
    self.RollingNumberTime = self._Control:GetClientConfig("PlugPointRollingNumberTime", 1, true) / 1000
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridBuffList = {}
end

function XUiGridScoreTowerStageNormal:OnDisable()
    self.Super.OnDisable(self)
    if self.RollingNumber then
        self.RollingNumber:Kill()
    end
end

function XUiGridScoreTowerStageNormal:RefreshOther(isAnim)
    -- 插件点图标
    local icon = self._Control:GetClientConfig("PlugPointIcon")
    if not string.IsNilOrEmpty(icon) then
        self.ImgIcon:SetSprite(icon)
    end
    -- 刷新插件数量
    local curPlugPoint = self._Control:GetStageTotalPlugPoint(self.ChapterId, self.TowerId, self.StageId)
    self.MaxPlugPoint = self._Control:GetStageMaxPlugPoint(self.StageId)
    -- 插件点上限
    curPlugPoint = curPlugPoint > self.MaxPlugPoint and self.MaxPlugPoint or curPlugPoint
    if not isAnim then
        self.CurPlugPoint = curPlugPoint
        self.TxtNum.text = string.format("%s/%s", curPlugPoint, self.MaxPlugPoint)
    else
        local startPlugPoint = self.CurPlugPoint
        local endPlugPoint = curPlugPoint
        self.CurPlugPoint = curPlugPoint
        if startPlugPoint >= endPlugPoint then
            self.TxtNum.text = string.format("%s/%s", curPlugPoint, self.MaxPlugPoint)
        else
            self:PlayRollingNumber(startPlugPoint, endPlugPoint)
        end
    end
    -- 刷新buff
    self:RefreshBuff()
end

function XUiGridScoreTowerStageNormal:RefreshBuff()
    local tagIds = self._Control:GetStageSuggestTagIds(self.StageId)
    if XTool.IsTableEmpty(tagIds) then
        self.ListBuff.gameObject:SetActiveEx(false)
        return
    end

    self.ListBuff.gameObject:SetActiveEx(true)
    for index, tagId in pairs(tagIds) do
        local buff = self.GridBuffList[index]
        if not buff then
            buff = XUiHelper.Instantiate(self.GridBuff, self.ListBuff)
            self.GridBuffList[index] = buff
        end
        buff.gameObject:SetActiveEx(true)
        local icon = self._Control:GetTagIcon(tagId)
        if not string.IsNilOrEmpty(icon) then
            buff:GetObject("RImgBuff"):SetRawImage(icon)
        end
    end
    for index = #tagIds + 1, #self.GridBuffList do
        self.GridBuffList[index].gameObject:SetActiveEx(false)
    end
end

-- 播放插件点滚动数字
---@param startPlugPoint number 开始插件点
---@param endPlugPoint number 结束插件点
function XUiGridScoreTowerStageNormal:PlayRollingNumber(startPlugPoint, endPlugPoint)
    if not self.RollingNumber then
        ---@type XUiCommonRollingNumber
        self.RollingNumber = XUiCommonRollingNumber.New(handler(self, self.RollingStart), handler(self, self.RollingRefresh),
            handler(self, self.RollingEnd))
    end
    self.RollingNumber:Play(startPlugPoint, endPlugPoint, self.RollingNumberTime)
end

function XUiGridScoreTowerStageNormal:RollingStart()
    -- TODO 播放音效或者特效
end

function XUiGridScoreTowerStageNormal:RollingRefresh(value)
    self.TxtNum.text = string.format("%s/%s", value, self.MaxPlugPoint)
end

function XUiGridScoreTowerStageNormal:RollingEnd()
    self.TxtNum.text = string.format("%s/%s", self.CurPlugPoint, self.MaxPlugPoint)
end

function XUiGridScoreTowerStageNormal:GetStageEntityId(index)
    -- 判断关卡是否通关
    local isPass = self._Control:IsStagePass(self.ChapterId, self.TowerId, self.StageId)
    if not isPass then
        return 0
    end
    return self.StageTeam:GetEntityIdByIndex(index) or 0
end

function XUiGridScoreTowerStageNormal:IsRecommendTag(entityId)
    return false
end

function XUiGridScoreTowerStageNormal:IsHideCharacterInfo()
    return true
end

return XUiGridScoreTowerStageNormal

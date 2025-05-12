local XUiTheatre4TimeBackDesc = require("XUi/XUiTheatre4/Game/Bubble/XUiTheatre4TimeBackDesc")

---@class XUiTheatre4BubbleBacktrack : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4BubbleBacktrack = XLuaUiManager.Register(XLuaUi, "UiTheatre4BubbleBacktrack")

function XUiTheatre4BubbleBacktrack:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBacktrack, self.OnBtnTimeBack)
    ---@type XUiTheatre4TimeBackDesc[]
    self._DescList = {
        XUiTheatre4TimeBackDesc.New(self.GridDetail1, self),
        XUiTheatre4TimeBackDesc.New(self.GridDetail2, self),
        XUiTheatre4TimeBackDesc.New(self.GridDetail3, self),
        XUiTheatre4TimeBackDesc.New(self.GridDetail4, self),
    }
end

---@param isClick boolean 是否接受点击
function XUiTheatre4BubbleBacktrack:OnStart(position, sizeDelta, isClick)
    self:SetPosition(position, sizeDelta)
    self.IsClick = isClick
end

-- 设置坐标
function XUiTheatre4BubbleBacktrack:SetPosition(position, sizeDelta)
    XScheduleManager.ScheduleOnce(function()
        -- 世界坐标转Ui坐标
        local localPosition = self.Transform:InverseTransformPoint(position)
        localPosition.x = localPosition.x - sizeDelta.x / 2
        localPosition.y = localPosition.y + sizeDelta.y / 2 + self.PanelBuild.sizeDelta.y / 2
        self.PanelBuild.localPosition = localPosition
    end, 1) --异形屏适配需要延迟一帧
end

function XUiTheatre4BubbleBacktrack:OnEnable()
    self:UpdateDescList()
    if self._Control.EffectSubControl:HasEnoughTimeBackData()
            -- 次数大于0按钮才亮起来
            and self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.TimeBack) > 0
    then
        self.BtnBacktrack:SetButtonState(XUiButtonState.Normal)
    else
        self.BtnBacktrack:SetButtonState(XUiButtonState.Disable)
    end
end

function XUiTheatre4BubbleBacktrack:OnBtnCloseClick()
    self:Close()
end

function XUiTheatre4BubbleBacktrack:OnBtnTimeBack()
    if not self._Control.EffectSubControl:HasEnoughTimeBackData() then
        return
    end
    self._Control.EffectSubControl:TimeBack()
end

function XUiTheatre4BubbleBacktrack:UpdateDescList()
    local descList = self._Control.EffectSubControl:GetTimeBackDescList()
    local list = {}

    -- 行动点数
    local tracbackDatas = self._Control.EffectSubControl:GetTracebackDatas()
    local value1 = 0
    if tracbackDatas then
        for _, tracebackData in pairs(tracbackDatas) do
            if tracebackData.CostAp then
                value1 = value1 + tracebackData.CostAp
            end
        end
    end
    local data = {
        Value = value1,
        Params = descList[1],
    }
    list[#list + 1] = data

    --region 获取配置
    ---@type XTableTheatre4Traceback
    local tracebackCfg = nil
    local minDay = 0
    local adventureData = self._Control.AssetSubControl:GetAdventureData()
    if adventureData then
        local curMapId = self._Control.MapSubControl:GetCurrentMapId()
        local chapterData = adventureData:GetChapterData(curMapId)
        if chapterData then
            local timeBackDays = chapterData:GetMaxTracebackDays()
            minDay = adventureData:GetDays() - timeBackDays
            local mapId = chapterData:GetMapId()
            local mapConfig = self._Control.MapSubControl:GetMapConfigById(mapId)
            if mapConfig then
                local traceBackGroupId = mapConfig.TracebackGroupId
                if traceBackGroupId and traceBackGroupId > 0 then
                    local difficulty = self._Control:GetDifficulty()
                    tracebackCfg = self._Control:GetTraceBackConfigByIdAndDifficulty(traceBackGroupId, difficulty)
                end
            end
        end
    end
    --endregion 获取配置

    if tracebackCfg then
        -- 钱
        if tracebackCfg.GoldReturnRate > 0 then
            --  银币
            local value2 = 0
            if tracbackDatas then
                for _, tracebackData in pairs(tracbackDatas) do
                    if tracebackData.CostGold then
                        value2 = value2 + tracebackData.CostGold
                    end
                end
            end
            local data = {
                Value = value2,
                Params = descList[2],
            }
            list[#list + 1] = data
        end

        -- 建筑许可
        if tracebackCfg.BuildPointReturnRate > 0 then
            local value3 = 0
            if tracbackDatas then
                for _, tracebackData in pairs(tracbackDatas) do
                    if tracebackData.CostBp then
                        value3 = value3 + tracebackData.CostBp
                    end
                end
            end
            local data = {
                Value = value3,
                Params = descList[3],
            }
            list[#list + 1] = data
        end

        -- 颜色倍率
        if tracebackCfg.ColorLevelReduceRate > 0 then
            local value4 = 0
            if tracbackDatas then
                if minDay > 0 then
                    local minDaysData = tracbackDatas[minDay]
                    if minDaysData then
                        local colors = self._Control.AssetSubControl:GetColorDatas()
                        for _, curColorTalent in ipairs(colors) do
                            local tracebackColorTalent = nil
                            for _, colorTalent in ipairs(minDaysData.Colors) do
                                if colorTalent.Color == curColorTalent.Color then
                                    tracebackColorTalent = colorTalent
                                    break
                                end
                            end

                            if tracebackColorTalent ~= nil then
                                -- 按比例减少等级
                                local diffLevel = curColorTalent.Level - tracebackColorTalent.Level
                                local reduceLevel = math.floor(diffLevel * tracebackCfg.ColorLevelReduceRate)
                                reduceLevel = math.min(reduceLevel, tracebackCfg.ColorLevelReduceMax)
                                reduceLevel = math.min(reduceLevel, curColorTalent.Level)

                                -- 按比例减少资源
                                local diffResource = curColorTalent.Resource - tracebackColorTalent.Resource
                                local reduceResource = math.floor(diffResource * tracebackCfg.ColorResourceReduceRate)
                                reduceResource = math.min(reduceResource, tracebackCfg.ColorResourceReduceMax)
                                reduceResource = math.min(reduceResource, curColorTalent.Resource)
                                if reduceResource > 0 then
                                    value4 = value4 + reduceResource
                                elseif reduceResource < 0 then
                                    XLog.Error("[XUiTheatre4BubbleBacktrack] reduceResource 应该大于0吧")
                                end
                            end
                        end
                    end
                end
            end
            local data = {
                Value = value4,
                Params = descList[4],
            }
            list[#list + 1] = data
        end
    end

    XTool.UpdateDynamicItem(self._DescList, list, self.GridDetail1, XUiTheatre4TimeBackDesc, self)
end

return XUiTheatre4BubbleBacktrack

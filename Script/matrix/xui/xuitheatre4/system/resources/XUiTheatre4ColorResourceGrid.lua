local XUiTheatre4RollingNumber = require("XUi/XUiTheatre4/Common/XUiTheatre4RollingNumber")
---@class XUiTheatre4ColorResourceGrid : XUiNode
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4ColorResource
---@field ResourceCountText XUiSpriteText
---@field LevelCountText XUiSpriteText
---@field LastCountText XUiSpriteText
local XUiTheatre4ColorResourceGrid = XClass(XUiNode, "XUiTheatre4ColorResourceGrid")

function XUiTheatre4ColorResourceGrid:OnStart()
    self.PanelResourceChange.gameObject:SetActiveEx(false)
    self.PanelLevelChange.gameObject:SetActiveEx(false)
    if self.PanelLastChange then
        self.PanelLastChange.gameObject:SetActiveEx(false)
    end
    if self.ImgRateBg then
        self.ImgRateBg.gameObject:SetActiveEx(false)
    end
    self._Control:RegisterClickEvent(self, self.Button, self.OnBtnClick)
    self.ImgColorBg = {
        [XEnumConst.Theatre4.ColorType.Red] = {
            On = self.ImgRedBgOn,
            Off = self.ImgRedBgOff,
        },
        [XEnumConst.Theatre4.ColorType.Yellow] = {
            On = self.ImgYellowBgOn,
            Off = self.ImgYellowBgOff,
        },
        [XEnumConst.Theatre4.ColorType.Blue] = {
            On = self.ImgBlueBgOn,
            Off = self.ImgBlueBgOff,
        },
    }
    self.ImgColorBar = {
        [XEnumConst.Theatre4.ColorType.Red] = self.ImgBarRed,
        [XEnumConst.Theatre4.ColorType.Yellow] = self.ImgBarYellow,
        [XEnumConst.Theatre4.ColorType.Blue] = self.ImgBarBlue,
    }
    self.ColorId = 0
    self.ColorResource = 0
    self.ColorLevel = 0
    self.MarkupRate = 0
    ---@type XUiTheatre4RollingNumber
    self.ResourceNumber = false
    ---@type XUiTheatre4RollingNumber
    self.LevelNumber = false
    -- 正在播放特效
    self.IsPlayingEffect = {}
    -- 隐藏特效节点
    self:HideEffect()

    if self.ImgBarRedNow then
        self.ImgBarRedNow.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4ColorResourceGrid:OnDisable()
    if self.ResourceNumber then
        self.ResourceNumber:StopTimer()
    end
    if self.LevelNumber then
        self.LevelNumber:StopTimer()
    end
    self.IsPlayingEffect = {}
    -- 隐藏特效节点
    self:HideEffect()
    self.ColorId = 0
    self.ColorResource = 0
    self.ColorLevel = 0
    self.MarkupRate = 0
end

-- 获取颜色资源
function XUiTheatre4ColorResourceGrid:GetColorResource()
    return self.ColorResource
end

-- 获取颜色等级
function XUiTheatre4ColorResourceGrid:GetColorLevel()
    return self.ColorLevel
end

-- 获取倍率
function XUiTheatre4ColorResourceGrid:GetMarkupRate()
    return self.MarkupRate
end

function XUiTheatre4ColorResourceGrid:Refresh(id, isAnim)
    local colorResource = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColorResource, id)
    local colorDailyResource = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColorDailyResource, id)
    local colorLevel = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColorLevel, id)
    local point = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColoPoint, id)
    local colorTalentLevel = self._Control:GetColorTalentLevel(id, point)
    self:SetData(id, colorResource + colorDailyResource, colorLevel, colorTalentLevel, true, isAnim)
end

---@param data { Id:number, Resource:number, Level:number, TalentLevel:number }
function XUiTheatre4ColorResourceGrid:RefreshData(data)
    self:SetData(data.Id, data.Resource, data.Level, data.TalentLevel, false, false)
end

function XUiTheatre4ColorResourceGrid:SetData(id, colorResource, colorLevel, colorTalentLevel, isShowBar, isAnim)
    self.ColorId = id
    self.MarkupRate = 0
    -- 颜色资源
    self:RefreshColorResource(colorResource, isAnim)
    -- 颜色等级
    self:RefreshColorLevel(colorLevel, isAnim)
    -- 颜色天赋等级
    self:RefreshColorTalentLevel(colorTalentLevel)
    -- 颜色背景
    self:RefreshColorBg()
    -- 进度条
    self:RefreshColorBar(colorTalentLevel, isShowBar)
end

-- 设置颜色资源
function XUiTheatre4ColorResourceGrid:SetTxtColourNum(colorResource)
    self.ImgColorBg[self.ColorId].On:GetObject("TxtColourNum").text = colorResource
    self.ImgColorBg[self.ColorId].Off:GetObject("TxtColourNum").text = colorResource
end

-- 设置颜色资源完成
function XUiTheatre4ColorResourceGrid:SetTxtColourFinish(colorResource)
    self.ColorResource = colorResource
    self:SetTxtColourNum(colorResource)
end

-- 刷新颜色资源
function XUiTheatre4ColorResourceGrid:RefreshColorResource(colorResource, isAnim)
    if isAnim and colorResource > self.ColorResource then
        self:PlayColorResourceAnim(colorResource)
    else
        if self.ResourceNumber then
            self.ResourceNumber:StopTimer()
        end
        self:SetTxtColourFinish(colorResource)
    end
end

-- 播放颜色资源动画
function XUiTheatre4ColorResourceGrid:PlayColorResourceAnim(colorResource)
    local effectValue = "Resource"
    if not self.ResourceNumber then
        self.ResourceNumber = XUiTheatre4RollingNumber.New(function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetTxtColourNum(value)
        end, function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetTxtColourFinish(value)
            self:HideChangeEffect(effectValue)
        end, self.Parent.IsPlayAudio)
    end
    local duration = self._Control:GetClientConfig("ResourceRollingNumberTime", 1, true) / 1000
    self.ResourceNumber:SetData(self.ColorResource, colorResource, duration)
    self:PlayChangeEffect(effectValue)
end

-- 设置颜色等级
function XUiTheatre4ColorResourceGrid:SetTxtLevelNum(colorLevel)
    self.TxtLvNumOn.text = string.format("×%s", colorLevel)
    self.TxtLvNumOff.text = string.format("×%s", colorLevel)
    self.TxtLvNumOn.gameObject:SetActiveEx(colorLevel > 0)
    self.TxtLvNumOff.gameObject:SetActiveEx(colorLevel > 0)
    self.ImgColorBg[self.ColorId].On:GetObject("ImgLvBg").gameObject:SetActiveEx(colorLevel > 0)
    self.ImgColorBg[self.ColorId].Off:GetObject("ImgLvBg").gameObject:SetActiveEx(colorLevel > 0)
end

-- 设置颜色等级完成
function XUiTheatre4ColorResourceGrid:SetTxtLevelFinish(colorLevel)
    self.ColorLevel = colorLevel
    self:SetTxtLevelNum(colorLevel)
end

-- 刷新颜色等级
function XUiTheatre4ColorResourceGrid:RefreshColorLevel(colorLevel, isAnim)
    if isAnim and colorLevel > self.ColorLevel then
        self:PlayColorLevelAnim(colorLevel)
    else
        if self.LevelNumber then
            self.LevelNumber:StopTimer()
        end
        self:SetTxtLevelFinish(colorLevel)
    end
end

-- 播放颜色等级动画
function XUiTheatre4ColorResourceGrid:PlayColorLevelAnim(colorLevel)
    local effectValue = "Level"
    if not self.LevelNumber then
        self.LevelNumber = XUiTheatre4RollingNumber.New(function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetTxtLevelNum(value)
        end, function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetTxtLevelFinish(value)
            self:HideChangeEffect(effectValue)
        end, self.Parent.IsPlayAudio)
    end
    local duration = self._Control:GetClientConfig("LevelRollingNumberTime", 1, true) / 1000
    self.LevelNumber:SetData(self.ColorLevel, colorLevel, duration)
    self:PlayChangeEffect(effectValue)
end

-- 刷新颜色天赋等级
function XUiTheatre4ColorResourceGrid:RefreshColorTalentLevel(colorTalentLevel)
    self.TxtClassNumOn.text = string.format("Lv.%s", colorTalentLevel)
    self.TxtClassNumOff.text = string.format("Lv.%s", colorTalentLevel)
    self.PanelClassOn.gameObject:SetActiveEx(colorTalentLevel >= 0)
    self.PanelClassOff.gameObject:SetActiveEx(colorTalentLevel >= 0)
end

-- 刷新颜色背景
function XUiTheatre4ColorResourceGrid:RefreshColorBg()
    for i, v in pairs(self.ImgColorBg) do
        v.On.gameObject:SetActiveEx(i == self.ColorId)
        v.Off.gameObject:SetActiveEx(i == self.ColorId)
    end
end

-- 刷新进度条
function XUiTheatre4ColorResourceGrid:RefreshColorBar(colorTalentLevel, isShowBar)
    self.PanelBar.gameObject:SetActiveEx(isShowBar)
    if isShowBar then
        local isMaxLevel = self._Control:CheckColorTalentIsMaxLevel(self.ColorId, colorTalentLevel)
        if isMaxLevel then
            self.ImgColorBar[self.ColorId].fillAmount = 1
        else
            local curPoint, nextPoint = self._Control:GetColorTalentCurAndNextLevelPoint(self.ColorId, colorTalentLevel)
            self.ImgColorBar[self.ColorId].fillAmount = curPoint / nextPoint
        end
        for i, v in pairs(self.ImgColorBar) do
            v.gameObject:SetActiveEx(i == self.ColorId)
        end

        if self.ImgBarRedNow then
            -- 红色买死值
            if self.ColorId == XEnumConst.Theatre4.ColorType.Red and self._Control.EffectSubControl:GetEffectRedBuyDeadAvailable() then
                self.ImgBarRedNow.gameObject:SetActiveEx(true)
                local pointAccumulated = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColorCostPoint, self.ColorId)
                local curPoint, nextPoint = self._Control:GetColorTalentCurAndNextLevelPoint(self.ColorId, colorTalentLevel)
                self.ImgBarRedNow.fillAmount = pointAccumulated / nextPoint
            else
                self.ImgBarRedNow.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 刷新倍率
function XUiTheatre4ColorResourceGrid:RefreshMarkupRate(rate)
    self.MarkupRate = rate
    if self.ImgRateBg then
        self.ImgRateBg.gameObject:SetActiveEx(rate > 0)
        self.TxtRateNum.text = string.format("×%s", rate)
    end
end

-- 显示资源数字文本
function XUiTheatre4ColorResourceGrid:ShowResourceCountText(txtNum)
    txtNum = string.format("+%s", txtNum)
    self.ResourceCountText:TextToSprite(txtNum, 0)
    self.PanelResourceChange.gameObject:SetActiveEx(false)
    self.PanelResourceChange.gameObject:SetActiveEx(true)
end

-- 显示等级数字文本
function XUiTheatre4ColorResourceGrid:ShowLevelCountText(txtNum)
    txtNum = string.format("+%s", txtNum)
    self.LevelCountText:TextToSprite(txtNum, 0)
    self.PanelLevelChange.gameObject:SetActiveEx(false)
    self.PanelLevelChange.gameObject:SetActiveEx(true)
end

-- 显示倍率
function XUiTheatre4ColorResourceGrid:ShowMarkupRate(rate)
    if self.LastCountText then
        rate = string.format("x%s", rate)
        self.LastCountText:TextToSprite(rate, 0)
    end
    if self.PanelLastChange then
        self.PanelLastChange.gameObject:SetActiveEx(false)
        self.PanelLastChange.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre4ColorResourceGrid:OnBtnClick()
    if self.Parent.Callback then
        self.Parent.Callback(self.ColorId)
    end
end

--region 特效相关

-- 播放特效
function XUiTheatre4ColorResourceGrid:PlayChangeEffect(value)
    local effect = self.ImgColorBg[self.ColorId].On:GetObject("Effect", false)
    if not effect then
        return
    end
    self.IsPlayingEffect[value] = true
    if effect.gameObject.activeSelf then
        return
    end
    effect.gameObject:SetActiveEx(true)
end

-- 隐藏特效
function XUiTheatre4ColorResourceGrid:HideChangeEffect(value)
    local effect = self.ImgColorBg[self.ColorId].On:GetObject("Effect", false)
    if not effect then
        return
    end
    self.IsPlayingEffect[value] = false
    -- 有在播放时不隐藏
    for _, v in pairs(self.IsPlayingEffect) do
        if v then
            return
        end
    end
    self.IsPlayingEffect = {}
    effect.gameObject:SetActiveEx(false)
end

-- 直接隐藏特效
function XUiTheatre4ColorResourceGrid:HideEffect()
    for _, v in pairs(self.ImgColorBg) do
        local effect = v.On:GetObject("Effect", false)
        if effect then
            effect.gameObject:SetActiveEx(false)
        end
    end
end

--endregion

return XUiTheatre4ColorResourceGrid

---@class XUiPanelFrame : XUiNode 布局方案预览中的组件面板
local XUiPanelFrame = XClass(XUiNode, "XUiPanelFrame")
local XCustomUi = CS.XCustomUi

function XUiPanelFrame:OnStart()
    XTool.InitUiObject(self)
    self.FrameDict = {
        [XCustomUi.INDEX_BALLBOX] = self.FrameBallBox,
        [XCustomUi.INDEX_JOYSTICK] = self.FrameJoystick,
        [XCustomUi.INDEX_PORTRAIT] = self.FramePortrait,
        [XCustomUi.INDEX_ONLINE_PORTRAIT] = self.FrameOnlinePortrait,
        [XCustomUi.INDEX_ATTACK] = self.FrameAttack,
        [XCustomUi.INDEX_DODGE] = self.FrameDodge,
        [XCustomUi.INDEX_EXSKILL] = self.FrameExSkill,
        [XCustomUi.INDEX_ENERGYBAR] = self.FrameEnergyBar,
        [XCustomUi.INDEX_FOCUS] = self.FrameFocus,
        [XCustomUi.INDEX_MESSAGE] = self.FrameMsg,
        [XCustomUi.Interaction1] = self.Interaction1,
        [XCustomUi.Interaction2] = self.Interaction2,
        [XCustomUi.INDEX_ENEMY_INFORMATION] = self.FrameEnemyInformation,
        [XCustomUi.INDEX_ENEMY_BUFF] = self.FrameEnemyBuff,
        [XCustomUi.INDEX_ENEMY_GENERAL_SKILL] = self.FrameEnemyGeneralSkill,
        [XCustomUi.INDEX_GENERAL_SKILL] = self.FrameGeneralSkill,
        [XCustomUi.INDEX_COMBO] = self.FrameCombo,
        [XCustomUi.INDEX_INFO] = self.FrameInfo,
        [XCustomUi.INDEX_ROLES] = self.FrameRoles,
        [XCustomUi.INDEX_ROLES_BUFF] = self.FrameRolesBuff
    }
end

function XUiPanelFrame:Refresh()
    local customData = XCustomUi.Instance.Data
    local uiData = customData and customData.UiData
    if not uiData then
        return
    end

    self.AreaSize = Vector2(XCustomUi.SafeScreenArea.width, XCustomUi.SafeScreenArea.height)
    self.Transform:GetComponent("RectTransform").sizeDelta = self.AreaSize
    
    for _, objRectTra in pairs(self.FrameDict) do
        objRectTra.gameObject:SetActiveEx(false)
    end

    local objRectTra
    for index, customComponentData in pairs(uiData) do
        objRectTra = self.FrameDict[index]
        if not objRectTra then
            goto CONTINUE
        end

        -- 设置缩放
        local localScale = Vector3.one * customComponentData.Scale
        localScale.x = localScale.x * objRectTra.localScale.x < 0 and -localScale.x or localScale.x
        objRectTra.localScale = localScale
        -- 设置透明度
        local graphicsContainer = objRectTra:GetComponent("XGraphicContainer")
        if graphicsContainer then
            graphicsContainer:SetAlpha(customComponentData.Alpha)
        end
        -- 设置锚点坐标
        local sizeDelta = objRectTra:GetComponent("RectTransform").sizeDelta
        local anchorPos = Vector2(customComponentData.PositionX, customComponentData.PositionY)
        -- 超出边界检查
        local halfSize = sizeDelta / 2 * localScale.x
        anchorPos = Vector2.Max(Vector2.zero + halfSize, Vector2.Min(anchorPos, self.AreaSize - halfSize))
        objRectTra.anchoredPosition = anchorPos
        -- 设置显隐
        objRectTra.gameObject:SetActiveEx(customComponentData.IsActive)
        -- 球栏设置方向
        if index == XCustomUi.INDEX_BALLBOX then
            local ballDirectionScale = customData.BallDirection == 1 and -1 or 1
            localScale = objRectTra.localScale
            localScale.x = math.abs(localScale.x) * ballDirectionScale
            objRectTra.localScale = localScale

            localScale = Vector3(ballDirectionScale, 1, 1)
            objRectTra:Find("Balls"):GetComponent("RectTransform").localScale = localScale
            objRectTra:Find("PanelBallCount"):GetComponent("RectTransform").localScale = localScale
        end
        :: CONTINUE ::
    end
end

return XUiPanelFrame
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local XUiTemple2Util = require("XUi/XUiTemple2/XUiTemple2Util")

---@class XUiTemple2CheckBoardGrid : XUiNode
---@field _Control XTemple2Control
local XUiTemple2CheckBoardGrid = XClass(XUiNode, "XUiTemple2CheckBoardGrid")

function XUiTemple2CheckBoardGrid:OnStart()
    self._Data = false
    ---@type UnityEngine.UI.Image
    local image = self.Image
    local zero = Vector2.zero
    image.rectTransform.pivot = zero
    image.rectTransform.anchoredPosition = zero
    image.rectTransform.anchorMin = zero
    image.rectTransform.anchorMax = zero
    self._IsSetCenterPivot = false
    self._LastIcon = false
    self._HighLightColor = false
    self._IsHighLightColor = false
    self._LastPrefab = false
end

---@param data XUiTemple2CheckBoardGridData
function XUiTemple2CheckBoardGrid:Update(data)
    self._Data = data
    self:Update1(data)
    self:Update2(data)
    self:Update3(data)
end

---@param data XUiTemple2CheckBoardGridData
function XUiTemple2CheckBoardGrid:Update1(data)
    -- 指引用, 需要
    self.Transform.name = "Grid" .. data.X .. "_" .. data.Y
    if data.IsEmpty then
        self.Image.gameObject:SetActiveEx(false)
        if self.PanelScore then
            self.PanelScore.gameObject:SetActiveEx(false)
        else
            if self.TextScore then
                self.TextScore.gameObject:SetActiveEx(false)
            end
        end
    else
        if data.Rotation then
            ---@type UnityEngine.RectTransform
            local transform = self.Image.transform
            --transform.eulerAngles = Vector3(0, 0, -data.Rotation)
            if data.Rotation == 0 then
                transform.anchoredPosition = Vector2(0, 0)
            elseif data.Rotation == 90 then
                transform.anchoredPosition = Vector2(0, -XTemple2Enum.GRID_SIZE)
            elseif data.Rotation == 180 then
                transform.anchoredPosition = Vector2(-XTemple2Enum.GRID_SIZE, 0)
            elseif data.Rotation == 270 then
                transform.anchoredPosition = Vector2(0, 0)
            end
        end

        if self.PanelScore then
            --version 2.0
            if data.Score then
                self.TextScore.text = data.Score
                ---@type UnityEngine.UI.RawImage
                local textBg = self.TextBg
                textBg.color = data.Color
                self.PanelScore.gameObject:SetActiveEx(true)
            else
                self.PanelScore.gameObject:SetActiveEx(false)
            end
        else
            --version 1.0
            if self.TextScore then
                if data.Score then
                    self.TextScore.text = data.Score
                    self.TextScore.gameObject:SetActiveEx(true)
                else
                    self.TextScore.gameObject:SetActiveEx(false)
                end
            end
        end
    end
end

---@param data XUiTemple2CheckBoardGridData
function XUiTemple2CheckBoardGrid:Update2(data)
    if self.BgRed then
        if data.IsRed then
            self.BgRed.gameObject:SetActiveEx(true)
        else
            self.BgRed.gameObject:SetActiveEx(false)
        end
    end

    if self.Floor then
        if data.IsShowLine then
            self.Floor.gameObject:SetActiveEx(true)
        else
            self.Floor.gameObject:SetActiveEx(false)
        end
    end

    if self.Mask then
        self.Mask.gameObject:SetActiveEx(data.MaskExit)
    end

    if self.Bg2 then
        if not data.IsEmpty and data.Icon and data.Color then
            self.Bg2.gameObject:SetActiveEx(true)
            self.Bg2.color = data.Color
        else
            self.Bg2.gameObject:SetActiveEx(false)
        end
    end

    local isActiveIcon = false
    if not data.IsEmpty and data.Icon2Instantiate then
        XUiTemple2Util.ActiveIcon(self, data)
        isActiveIcon = true
    end

    if self.HighLight then
        if self._IsHighLightColor ~= data.IsHighLight then
            self._IsHighLightColor = data.IsHighLight
            self.HighLight.gameObject:SetActiveEx(data.IsHighLight)
            if data.IsHighLight and data.HighLightColor then
                if self._HighLightColor ~= data.HighLightColor then
                    self._HighLightColor = data.HighLightColor
                    self.HighLight.color = data.HighLightColor
                end
            end
        end
    end

    if self.PanelPoints then
        self.PanelPoints.gameObject:SetActiveEx(false)
    end

    if data.IsShowNpc then
        self._NpcData = self._NpcData or {
            Icon2Instantiate = "Npc"
        }
        local object = XUiTemple2Util.ActiveIcon(self, self._NpcData)
        object.gameObject:SetActiveEx(true)
    end
    if not self:SetPathVisible(data.Path) and not data.IsShowNpc and not isActiveIcon then
        XUiTemple2Util.ActiveIcon(self, false)
    end
end

---@param data XUiTemple2CheckBoardGridData
function XUiTemple2CheckBoardGrid:Update3(data)
    if data.IsEmpty then
        if self._LastPrefab then
            self._LastPrefab.gameObject:SetActiveEx(false)
        end
    else
        if data.Prefab and (data.Rotation == 0 or data.Rotation == 180) then
            local prefab = self:GetPrefab(data.Prefab)
            if prefab then
                self._LastPrefab = prefab
                prefab.gameObject:SetActiveEx(true)
            end
            self.Image.gameObject:SetActiveEx(false)

            -- 旋转后, 动画
            if data.Rotation == 180 then
                prefab.transform.anchoredPosition = Vector2(-XTemple2Enum.GRID_SIZE, 0)
            elseif data.Rotation == 0 then
                prefab.transform.anchoredPosition = Vector2(0, 0)
            end
        else
            if self._LastPrefab then
                self._LastPrefab.gameObject:SetActiveEx(false)
            end

            if data.Icon then
                self.Image.gameObject:SetActiveEx(true)
                if data.Icon ~= self._LastIcon then
                    self._LastIcon = data.Icon
                    self.Image:SetSprite(data.Icon, function()
                        if self.Image then
                            self.Image:SetNativeSize()
                            if data.LimitSize then
                                ---@type UnityEngine.RectTransform
                                local transform = self.Image.transform
                                if transform.rect.width > 160 or transform.rect.height > 160 then
                                    transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 160)
                                    transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, 160)
                                end
                            end
                        end
                    end)
                end
            else
                self.Image.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiTemple2CheckBoardGrid:GetPrefab(path)
    --缓存没用, loadPrefab底层做了回收
    local prefab = self.GameObject:LoadPrefab(path)
    return prefab
end

function XUiTemple2CheckBoardGrid:GetInstantiate(name)
    if not self._Icons[name] then
        local prefab = self[name]
        if prefab then
            local IconParent = self.IconParent
            if IconParent then
                self._Icons[name] = CS.UnityEngine.Object.Instantiate(prefab, IconParent)
                local instantiate = self._Icons[name]
                if instantiate then
                    local zero = Vector3.zero
                    instantiate.transform.localPosition = zero
                    instantiate.transform.localEulerAngles = zero
                end
            end
        end
    end
    return self._Icons[name]
end

function XUiTemple2CheckBoardGrid:SetPathVisible(value)
    if value then
        if not self._UiPreview then
            self._UiPreview = CS.UnityEngine.GameObject.Instantiate(self.GridPreview.gameObject)
            self._UiPreview.transform:SetParent(self.Path or self.Transform)
            self._UiPreview.transform.localPosition = CS.UnityEngine.Vector3.zero
            self._UiPreview.transform.localScale = CS.UnityEngine.Vector3.one
        end
        self._UiPreview.gameObject:SetActiveEx(true)
        self._ArrowData = self._ArrowData or {
            Icon2Instantiate = "Arrow"
        }
        return self:SetArrow(self._ArrowData, value)
    else
        if self._UiPreview then
            self._UiPreview.gameObject:SetActiveEx(false)
        end
        return self:SetArrow(false)
    end
end

function XUiTemple2CheckBoardGrid:IsPositionAndActive(x, y)
    if self._Data then
        if self._Data.X == x and self._Data.Y == y then
            if self.GameObject and self.GameObject.activeInHierarchy then
                return true
            end
        end
    end
    return false
end

function XUiTemple2CheckBoardGrid:SetPivotCenter()
    if self._IsSetCenterPivot then
        return
    end
    self._IsSetCenterPivot = true
    ---@type UnityEngine.UI.Image
    local image = self.Image
    local center = Vector2(0.5, 0.5)
    image.rectTransform.pivot = center
    image.rectTransform.anchoredPosition = center
    image.rectTransform.anchorMin = center
    image.rectTransform.anchorMax = center
end

function XUiTemple2CheckBoardGrid:GetUiData()
    return self._Data
end

function XUiTemple2CheckBoardGrid:PlayScoreAnimation(score)
    if self.TxtPoints then
        self.TxtPoints.text = score
        self.PanelPoints.gameObject:SetActiveEx(false)
        self.PanelPoints.gameObject:SetActiveEx(true)
    end
end

---@param pathData XTemple2GameControlPathData
function XUiTemple2CheckBoardGrid:SetArrow(data, pathData)
    if data and pathData and pathData.IsPlay then
        local instantiate = XUiTemple2Util.ActiveIcon(self, data, true)
        if instantiate then
            if type(pathData) == "table" then
                if pathData.Direction then
                    if pathData.Direction.y > 0 then
                        instantiate.transform.localEulerAngles = Vector3(0, 0, 90)
                    elseif pathData.Direction.y < 0 then
                        instantiate.transform.localEulerAngles = Vector3(0, 0, -90)
                    elseif pathData.Direction.x > 0 then
                        instantiate.transform.localEulerAngles = Vector3(0, 0, 0)
                    elseif pathData.Direction.x < 0 then
                        instantiate.transform.localEulerAngles = Vector3(0, 0, 180)
                    end
                end
                if pathData.AnimationOffset then
                    ---@type UnityEngine.Playables.PlayableDirector
                    local playableDirector = XUiHelper.TryGetComponent(instantiate.transform, "Animation/Loop", "PlayableDirector")
                    playableDirector.time = (playableDirector.duration - pathData.AnimationOffset % playableDirector.duration)
                end
            end
        end
        return true
    end
    return false
end

return XUiTemple2CheckBoardGrid
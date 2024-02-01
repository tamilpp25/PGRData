---@class XUiGridFangKuaiBlock : XUiNode
---@field Parent XUiFangKuaiFight
---@field _Control XFangKuaiControl
local XUiGridFangKuaiBlock = XClass(XUiNode, "XUiGridFangKuaiBlock")

--region 生命周期

function XUiGridFangKuaiBlock:OnStart()
    self._Bodys = {}
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnChooseBlock)
    ---@type XUiButtonLongClick
    self._LongClick = XUiButtonLongClick.New(self.BtnLongClick, 10, self, nil, self.OnLongClickBlock, self.OnUpClickBlock)
    self._LongClick:AddFocusExitListener(handler(self, self.OnFocusExit))
end

---@param blockData XFangKuaiBlock
function XUiGridFangKuaiBlock:Init(blockData)
    self:Open()
    self.BlockData = blockData
    self:UpdateBlock()
    self:UpdatePosition()
    self:AllowLongClick(true)
    self:AllowClick(false)
    self:PlayExpression(XEnumConst.FangKuai.Expression.Standby)
end

function XUiGridFangKuaiBlock:Recycle()
    self.BlockData = nil
    self:RemoveTimer()
    for _, body in pairs(self._Bodys) do
        body.transform.gameObject:SetActiveEx(false)
    end
    self:Close()
end

function XUiGridFangKuaiBlock:OnDestroy()
    self:RemoveTimer()
end

--endregion

function XUiGridFangKuaiBlock:UpdatePosition()
    local posX, posY = self._Control:GetPosByBlock(self.BlockData)
    self.Transform.localPosition = CS.UnityEngine.Vector3(posX, posY, 0)
    self.Transform.localScale = CS.UnityEngine.Vector3(self.BlockData:IsFacingLeft() and 1 or -1, 1, 1)
    self:UpdateContentWidth()
end

function XUiGridFangKuaiBlock:UpdatePositionX()
    local posX, _ = self._Control:GetPosByBlock(self.BlockData)
    local posY = self.Transform.localPosition.y
    self.Transform.localPosition = CS.UnityEngine.Vector3(posX, posY, 0)
    self:UpdateContentWidth()
end

---适配方块不同朝向
function XUiGridFangKuaiBlock:UpdateContentWidth()
    local posX
    local posY = self.Content.anchoredPosition.y
    if self.BlockData:IsFacingLeft() then
        posX = 0
    else
        local blockWidth = self._Control:GetPosByGridX(self.BlockData:GetLen())
        posX = -blockWidth
    end
    self.Content.anchoredPosition = CS.UnityEngine.Vector2(posX, posY)
end

function XUiGridFangKuaiBlock:UpdateBlock()
    local textureConfig = self._Control:GetBlockTextureConfig(self.BlockData:GetColor())
    self.ImgOne:SetRawImage(textureConfig.StandaloneImage)
    self.ImgHead:SetRawImage(textureConfig.HeadImage)
    self.ImgTail:SetRawImage(textureConfig.TailImage)
    self.ImgBody:SetRawImage(textureConfig.BodyImage)

    local len = self.BlockData:GetLen()
    self.ImgOne.transform.gameObject:SetActiveEx(len == 1)
    self.ImgHead.transform.gameObject:SetActiveEx(len >= 2)
    self.ImgTail.transform.gameObject:SetActiveEx(len >= 2)
    self.ImgBody.transform.gameObject:SetActiveEx(len >= 3)
    if len >= 4 then
        for i = 4, len do
            local body = self._Bodys[i - 3]
            if not body then
                body = XUiHelper.Instantiate(self.ImgBody.transform, self.Content)
                body:SetSiblingIndex(3)
                table.insert(self._Bodys, body)
            end
            body:GetComponent("RawImage"):SetRawImage(textureConfig.BodyImage)
            body.transform.gameObject:SetActiveEx(true)
        end
    end
    for i = math.max(1, len - 2), #self._Bodys do
        self._Bodys[i].transform.gameObject:SetActiveEx(false)
    end

    local itemId = self.BlockData:GetItemId()
    if XTool.IsNumberValid(itemId) then
        local itemConfig = self._Control:GetItemConfig(itemId)
        self.RImgItem:SetRawImage(itemConfig.Icon)
        self.RImgItem.gameObject:SetActiveEx(true)
    else
        self.RImgItem.gameObject:SetActiveEx(false)
    end

    -- 编辑器下显示debug信息：方块Id
    if self._Control:IsDebug() then
        self.TxtDebug.gameObject:SetActiveEx(true)
        self.TxtDebug.text = string.format("%s\n%s", self.BlockData:GetId(), self.BlockData:GetScore())
        self.TxtDebug.transform.localScale = CS.UnityEngine.Vector3(self.BlockData:IsFacingLeft() and 1 or -1, 1, 1)
    else
        self.TxtDebug.gameObject:SetActiveEx(false)
    end
end

function XUiGridFangKuaiBlock:UpdateBlockLen()
    self:UpdateBlock()
    self:UpdatePositionX() -- 这里用self:UpdatePosition()会更新y坐标 直接就到目的地了
    self:PlayExpression(XEnumConst.FangKuai.Expression.Standby)
end

--region 长按操作

function XUiGridFangKuaiBlock:AllowLongClick(isForbid)
    self.BtnLongClick.gameObject:SetActiveEx(isForbid)
end

function XUiGridFangKuaiBlock:OnStartClickBlock()
    self:PlayExpression(XEnumConst.FangKuai.Expression.Click)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_STARTDRAG, self.BlockData)
end

function XUiGridFangKuaiBlock:OnLongClickBlock()
    if self.Parent:IsOtherClicking(self.BlockData:GetId()) then
        -- 不支持多点触屏
        return
    end
    if not self._InitGridX then
        self._InitGridX = self.BlockData:GetHeadGrid().x
        -- 如果点击尾部 则以尾部为基准进行移动
        self._MoveOffset = self._Control:GetMouseClickGrid(self) - self._InitGridX
        self._Control:PlayClickSound()
        self.Parent:SetCurClickBlockId(self.BlockData:GetId())
    end
    if not self._MinX or not self._MaxX then
        self._MinX, self._MaxX = self.Parent:GetBlockMoveArea(self.BlockData)
    end

    if not self._IsClicking then
        self:OnStartClickBlock()
    end
    self._IsClicking = true

    local gridX = self._Control:GetMouseClickGrid(self) - self._MoveOffset
    gridX = math.min(self._MaxX, math.max(self._MinX, gridX))
    local curBlock = self.BlockData:GetHeadGrid()
    if gridX ~= curBlock.x then
        self._IsMoving = true
        if self._Move then
            self._Move:Kill()
        end
        self._Move = self._Control:MoveX(self, gridX, function()
            self.Parent:UpdateCompareBgPos(self.Transform.anchoredPosition.x)
        end, function()
            self._IsMoving = false
            self:CheckOperateEnd()
        end)
        self.BlockData:UpdatePos(gridX)
    end
end

function XUiGridFangKuaiBlock:OnUpClickBlock()
    if self.Parent:IsOtherClicking(self.BlockData:GetId()) then
        return
    end
    self._MinX = nil
    self._MaxX = nil
    self._MoveOffset = 0
    self._IsClicking = false
    self:CheckOperateEnd()
end

function XUiGridFangKuaiBlock:CheckOperateEnd()
    local finalGrid = self.BlockData:GetHeadGrid()
    local isMoved = self._InitGridX and (self._InitGridX ~= finalGrid.x)
    if not self._IsClicking and not self._IsMoving then
        self._InitGridX = nil
        if isMoved then
            self.Parent:RecordLastItemCount()
            self._Control:SignGridOccupyAuto(self.BlockData)
            self._Control:FangKuaiBlockMoveRequest(self.Parent:GetChapterId(), self.BlockData:GetId(), math.floor(finalGrid.x - 1))
        end
        self:PlayExpression(XEnumConst.FangKuai.Expression.Standby)
        self.Parent:ClearClickBlockId()
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ENDDRAG, self.BlockData, isMoved)
    end
end

function XUiGridFangKuaiBlock:OnFocusExit()
    -- 焦点丢失 相当于放下方块
    if self._IsClicking then
        self._LongClick:OnUp()
    end
end

function XUiGridFangKuaiBlock:RemoveTimer()
    if self._RecycleTimer then
        XScheduleManager.UnSchedule(self._RecycleTimer)
        self._RecycleTimer = false
    end
end

--endregion

--region 点击操作

function XUiGridFangKuaiBlock:AllowClick(isForbid)
    self.BtnClick.gameObject:SetActiveEx(isForbid)
end

function XUiGridFangKuaiBlock:OnChooseBlock()
    self.Parent:OnClickBlock(self)
    self._Control:PlayClickSound()
end

--endregion

--region 消除

function XUiGridFangKuaiBlock:PlayClearUp(cb)
    -- 这里做消除时的表现
    self:PlayExpression(XEnumConst.FangKuai.Expression.ClearUp)
    self._RecycleTimer = XScheduleManager.ScheduleOnce(function()
        cb()
        self:Recycle()
    end, 800)
end

function XUiGridFangKuaiBlock:PlayBossWane(isClear)
    -- 等整行消除特效播完再缩短长度
    local delayTime = isClear and 800 or 300
    self.PanelEffect.gameObject:SetActiveEx(true)
    self:PlayExpression(XEnumConst.FangKuai.Expression.ClearUp)
    self._WaneTimer = XScheduleManager.ScheduleOnce(function()
        self:UpdateBlockLen()
        self.PanelEffect.gameObject:SetActiveEx(false)
    end, delayTime)
end

--endregion

--region 表情

function XUiGridFangKuaiBlock:PlayExpression(expression)
    -- 方块长度=1并且有道具时不显示表情
    if XTool.IsNumberValid(self.BlockData:GetItemId()) then
        self.RImgExpression.gameObject:SetActiveEx(false)
        return
    end
    local icon = self._Control:GetBlockExpression(expression, self.BlockData:IsBoss(), self.BlockData:GetColor())
    self.RImgExpression.gameObject:SetActiveEx(true)
    self.RImgExpression:SetRawImage(icon)
end

--endregion

--region Alpha

function XUiGridFangKuaiBlock:ChangeAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

--endregion

--region 引导

function XUiGridFangKuaiBlock:ForceMoveX(gridX)
    self._Move = self._Control:MoveX(self, gridX, function()
        self.Parent:UpdateCompareBgPos(self.Transform.anchoredPosition.x)
    end, function()
        local finalGrid = self.BlockData:GetHeadGrid()
        self.Parent:RecordLastItemCount()
        self._Control:SignGridOccupyAuto(self.BlockData)
        self._Control:FangKuaiBlockMoveRequest(self.Parent:GetChapterId(), self.BlockData:GetId(), math.floor(finalGrid.x - 1))
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_ENDDRAG, self.BlockData, true)
    end, 0.5)
    self.BlockData:UpdatePos(gridX)
end

--endregion

return XUiGridFangKuaiBlock
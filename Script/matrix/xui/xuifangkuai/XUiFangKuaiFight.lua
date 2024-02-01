---@class XUiFangKuaiFight : XLuaUi 大方块棋盘
---@field _Game XFangKuaiGame
---@field _Control XFangKuaiControl
---@field _Panel3D XUiPanelFangKuaiFight3D
---@field _NoticeBlocks table<number,XUiGridFangKuaiNoticeBlock[]>
---@field _BlockPool XObjectPool 方块池
---@field _BlockNoticePool XObjectPool 预告方块池
---@field _Speed number
---@field _BlockMap table<number, XUiGridFangKuaiBlock>
local XUiFangKuaiFight = XLuaUiManager.Register(XLuaUi, "UiFangKuaiFight")

local NoticeLine = {
    First = 1,
    Second = 2,
}
local BubblePos1 = CS.UnityEngine.Vector3(-70, 147, 0)
local BubblePos2 = CS.UnityEngine.Vector3(-80, 147, 0)

function XUiFangKuaiFight:OnAwake()
    self._BlockMap = {}
    self._NoticeBlocks = {}
    self._PlayNewItemAnimList = {}
    self._Effects = {}
    self._EffectTimer = {}
    self._MinShowCombo = self._Control:GetMinShowCombo()
    self._WarnDistance = self._Control:GetBlockWarnDistance()
    self._Alpha = self._Control:GetCannotUseAlpha()
    self._Panel3D = require("XUi/XUiFangKuai/XUiPanelFangKuaiFight3D").New(self)

    self._BlockPool = XObjectPool.New(function()
        return self:OnBlockCreate()
    end)

    self._BlockNoticePool = XObjectPool.New(function(lineIndex)
        return self:OnNoticeBlockCreate(lineIndex)
    end)

    self:RegisterClickEvent(self.BtnResetting, self.OnClickReset)
    self:RegisterClickEvent(self.BtnExit, self.OnClickExit)
    self:RegisterClickEvent(self.BtnScore, self.OnClickHelp)
    self:RegisterClickEvent(self.BtnClosePropOther, self.OnClickCancelUseItem)
    self:RegisterClickEvent(self.BtnAddTime, self.OnClickAddRound)
    self:RegisterChooseColorBtn()
end

---@param game XFangKuaiGame
function XUiFangKuaiFight:OnStart(game, isNewGame)
    self._Game = game
    self._IsNewGame = isNewGame
    self._StageId = game:GetCurFightStageId()
    self._ChapterId = game:GetCurFightChapterId()
    self._StageConfig = self._Control:GetStageConfig(self._StageId)
    self._IsNormal = self._Control:IsStageNormal(self._StageId)

    self:InitBlockPanel()
    self._Panel3D:InitSceneRoot()

    local roleNpcId = self._Control:GetCurShowNpcId()
    local role = self._Control:GetNpcActionConfig(roleNpcId)
    local boss = self._Control:GetNpcActionConfig(self._StageConfig.NpcId)
    self._Panel3D:ShowCharacterModel(role, boss)

    self.Block.gameObject:SetActiveEx(false)
    self.GridHeraldFangKuai.gameObject:SetActiveEx(false)
    self.RImgFlyItem.gameObject:SetActiveEx(false)
    self.PanelTs.gameObject:SetActiveEx(false)
    self.ImgRound1.gameObject:SetActiveEx(self._IsNormal)
    self.ImgRound2.gameObject:SetActiveEx(not self._IsNormal)

    self:UpdateItem()
    self:OnClickCancelUseItem()
    self:ForbidClick(false)
    self:HideOriginalBlock()
    self:HideCompareBg()
    self:ShowWarnEffect()

    self.EndTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFangKuaiFight:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateRound()
    self:UpdateScore()
    self:RecordLastItemCount()
    self:AddEventListener()
    self:StartCreateInitBlock(self._IsNewGame)
end

function XUiFangKuaiFight:OnDisable()
    self.Super.OnDisable(self)
    self:RemoveEventListener()
end

function XUiFangKuaiFight:OnDestroy()
    self._Panel3D:Destroy()
    self._BlockPool:Clear()
    self._BlockNoticePool:Clear()
    self._BlockMap = {}
    self._NoticeBlocks = {}
    self:RemoveTimer()
end

function XUiFangKuaiFight:InitBlockPanel()
    local blockDatas = self._Game:GetBlockMap()
    for blockData, _ in pairs(blockDatas) do
        self:AddBlock(blockData)
        self:OnLineAdd()
    end
end

function XUiFangKuaiFight:StartCreateInitBlock(isNewGame)
    if self._Game:IsBlockEmpty() then
        if isNewGame then
            self.GameStar.gameObject:SetActiveEx(true)
            self:PlayAnimationWithMask("GameStarEnable", function()
                self._Game:StartCreateInitBlock()
                self:ForbidClick(true)
                self.GameStar.gameObject:SetActiveEx(false)
            end)
        else
            self.GameStar.gameObject:SetActiveEx(false)
            self._Game:StartCreateInitBlock()
            self:ForbidClick(true)
        end
    end
end

--region 事件

function XUiFangKuaiFight:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_STARTDRAG, self.OnBlockDragStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_UPDATESCORE, self.OnScoreUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_UPDATESTAGE, self.OnStageUpdae, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_SRARTROUND, self.OnStartRound, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_USEITEMEND, self.OnUseItemEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ENDDRAG, self.OnBlockDragEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_REMOVE, self.OnBlockRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_GAMEOVER, self.OnGameOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_MOVEX, self.OnBlockMoveX, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_MOVEY, self.OnBlockMoveY, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ADDLINE, self.OnLineAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_CLEAR, self.OnLineClear, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_WANE, self.OnBlockWane, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_RESET, self.OnRestart, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_GUIDE, self.PlayGuide, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ADD, self.OnBlockAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_DROP, self.OnDrop, self)
end

function XUiFangKuaiFight:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_STARTDRAG, self.OnBlockDragStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_UPDATESCORE, self.OnScoreUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_UPDATESTAGE, self.OnStageUpdae, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_SRARTROUND, self.OnStartRound, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_USEITEMEND, self.OnUseItemEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ENDDRAG, self.OnBlockDragEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_REMOVE, self.OnBlockRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_GAMEOVER, self.OnGameOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_MOVEX, self.OnBlockMoveX, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_MOVEY, self.OnBlockMoveY, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ADDLINE, self.OnLineAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_CLEAR, self.OnLineClear, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_WANE, self.OnBlockWane, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_RESET, self.OnRestart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_GUIDE, self.PlayGuide, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ADD, self.OnBlockAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_DROP, self.OnDrop, self)
end

---开始新回合
function XUiFangKuaiFight:OnStartRound()
    self._PlayNewItemAnimList = {}
    self:UpdateRound()
    self:ForbidClick(false)
    self:ShowWarnEffect()
    self:OnLineAdd()
end

---开始移动
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockDragStart(blockData)
    self._Panel3D:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Move)
    self:ShowOriginalBlock(blockData)
    self:ShowCompareBg(blockData)
end

---移动结束
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockDragEnd(blockData, isMoved)
    self._Panel3D:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Standby)
    if isMoved then
        self._Game:StartRound(blockData:GetHeadGrid().y)
        self:ForbidClick(true)
    end
    self:HideOriginalBlock()
    self:HideCompareBg()
end

---消除
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockRemove(blockData, isImmediately)
    local block = self:GetBlock(blockData)
    if block then
        local itemId = blockData:GetItemId()
        if XTool.IsNumberValid(itemId) then
            local maxCount = self._Control:GetMaxItemCount()
            if not isImmediately and (not self._RecordItemCount or self._RecordItemCount < maxCount) then
                -- 使用以大化小造成的消除不需要飘道具（道具转移到第一个小方块上了）
                self:PlayFlyItem(block)
            elseif self._RecordItemCount >= maxCount then
                self:ShowTip(XUiHelper.GetText("FangKuaiItemFull"))
            end
            self:AddItemCount()
        end
        if isImmediately then
            self:BlockPoolRecycle(block)
            block:Recycle()
        else
            block:PlayClearUp(function()
                self:BlockPoolRecycle(block)
            end)
        end
        self._Panel3D:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Attack, 2000)
    end
    self:RemoveBlock(blockData)
end

---变短
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockWane(blockData, isClear)
    local block = self:GetBlock(blockData)
    if block then
        block:PlayBossWane(isClear)
    end
end

---上/下移N行
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockMoveY(blockData, gridY)
    local block = self:GetBlock(blockData)
    self._Control:MoveY(block, gridY)
    self:ShowWarnEffect()
end

---左/右移N格
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockMoveX(blockData, gridX)
    local block = self:GetBlock(blockData)
    self._Control:MoveX(block, gridX)
end

---添加新方块
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockAdd(blockData)
    self:AddBlock(blockData)
    self._Panel3D:PlayBossAnimation(XEnumConst.FangKuai.BossAnim.BossAttack, 2000)
end

---新行生成
function XUiFangKuaiFight:OnLineAdd()
    local noticeBlocks = self._Game:GetNewBlockNotice()
    self:ShowNoticeBlock(noticeBlocks)
end

---战斗结束
function XUiFangKuaiFight:OnGameOver()
    if not self._Game:IsGameOver() then
        -- 等待客户端流程结束后才弹结束框
        return
    end
    local settleData = self._Control:GetCurStageSettleData()
    if not settleData then
        -- 等待服务端返回协议
        return
    end
    if not XLuaUiManager.IsUiShow("UiFangKuaiSettlement") then
        -- 延迟1秒 等所有表现播放再弹
        local delay = self._Control:GetOpenSettleDelay()
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
            XLuaUiManager.Open("UiFangKuaiSettlement", self._StageId, function()
                -- 退出游戏
                XLuaUiManager.Remove("UiFangKuaiChapterDetail")
                self._Control:ClearFightData(self._StageId)
                self:Close()
            end, function()
                -- 重新开始
                self:RestartGame()
            end)
        end, delay)
    end
end

---播消除行特效
function XUiFangKuaiFight:OnLineClear(gridYs)
    for _, arg in ipairs(gridYs) do
        local gridY = arg[1]
        local go = self._Effects[gridY]
        if not go then
            if XTool.IsTableEmpty(self._Effects) then
                go = self.PaneSingleLineRemoveEffect -- 放到第一个消除行那
            else
                go = XUiHelper.Instantiate(self.PaneSingleLineRemoveEffect, self.PaneSingleLineRemoveEffect.parent)
            end
            local posX = go.localPosition.x
            local posY = self._Control:GetPosByGridY(gridY)
            go.localPosition = CS.UnityEngine.Vector3(posX, posY - 10, 0)
            self._Effects[gridY] = go
        end
        go.gameObject:SetActiveEx(true)
        self._EffectTimer[gridY] = XScheduleManager.ScheduleOnce(function()
            go.gameObject:SetActiveEx(false)
        end, 800)
    end
end

-- 执行道具操作期间 屏蔽方块和道具点击
function XUiFangKuaiFight:OnUseItemEnd()
    self:ForbidClick(false)
end

function XUiFangKuaiFight:RestartGame()
    self._Round = nil
    self._Control:RestartGame(self._StageId, handler(self, self.OnRestart))
    self:ShowWarnEffect()
end

function XUiFangKuaiFight:OnScoreUpdate()
    self:UpdateScore()
    self:ShowCombo()
end

function XUiFangKuaiFight:OnBlockCreate()
    local cell = XUiHelper.Instantiate(self.Block, self.BlockContent)
    return require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiBlock").New(cell, self)
end

function XUiFangKuaiFight:OnNoticeBlockCreate(lineIndex)
    local content = lineIndex == NoticeLine.First and self.Herald1 or self.Herald2
    local cell = XUiHelper.Instantiate(self.GridHeraldFangKuai, content)
    return require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiNoticeBlock").New(cell, self)
end

function XUiFangKuaiFight:OnClear()
    for _, block in pairs(self._BlockMap) do
        block:Close()
        self:BlockPoolRecycle(block)
    end
    for _, notices in pairs(self._NoticeBlocks) do
        for _, notice in pairs(notices) do
            notice:Close()
            self._BlockNoticePool:Recycle(notice)
        end
    end
    self._BlockMap = {}
    self._NoticeBlocks = {}
end

function XUiFangKuaiFight:OnRestart()
    self:OnClear()
    self:InitBlockPanel()
    self:UpdateItem()
    self:OnClickCancelUseItem()
    self:UpdateScore()
    self:UpdateRound()
    self:StartCreateInitBlock(true)
end

function XUiFangKuaiFight:OnStageUpdae()
    if not self._Control:IsStageFinished() then
        self:UpdateItem()
    end
    self:UpdateRound()
end

function XUiFangKuaiFight:OnDrop()
    self._Control:PlayDropSound()
end

--endregion

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:GetBlock(blockData)
    local block = self._BlockMap[blockData:GetId()]
    if not block then
        local curGrid = blockData:GetHeadGrid()
        XLog.Error(string.format("没有找到 x=%s,y=%s 所属的方块", curGrid.x, curGrid.y))
    end
    if not block.BlockData then
        XLog.Error("BlockData null")
    end
    return block
end

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:AddBlock(blockData)
    local block = self._BlockPool:Create(blockData)
    self._BlockMap[block.BlockData:GetId()] = block
end

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:RemoveBlock(blockData)
    self._BlockMap[blockData:GetId()] = nil
end

-- 使用道具时方块不接受长按事件；移动方块时不接受点击事件
function XUiFangKuaiFight:ForbidBlock(canMove, canClick)
    for _, block in pairs(self._BlockMap) do
        block:AllowLongClick(canMove)
        block:AllowClick(canClick)
    end
end

function XUiFangKuaiFight:GetBlockMoveArea(blockData)
    return self._Game:GetBlockMoveArea(blockData)
end

--region 方块预告

---@param blockDatas table<number,XFangKuaiBlock[]>
function XUiFangKuaiFight:ShowNoticeBlock(blockDatas)
    self:RecycleNoticeBlock(NoticeLine.First)
    self:RecycleNoticeBlock(NoticeLine.Second)

    if blockDatas[NoticeLine.First] then
        self.Herald1.gameObject:SetActiveEx(true)
        self:CreateNoticeBlock(blockDatas[NoticeLine.First], NoticeLine.First)
    else
        self.Herald1.gameObject:SetActiveEx(false)
    end

    if blockDatas[NoticeLine.Second] then
        self.Herald2.gameObject:SetActiveEx(true)
        self:CreateNoticeBlock(blockDatas[NoticeLine.Second], NoticeLine.Second)
    else
        self.Herald2.gameObject:SetActiveEx(false)
    end
end

function XUiFangKuaiFight:RecycleNoticeBlock(lineIndex)
    local blocks = self._NoticeBlocks[lineIndex]
    if not XTool.IsTableEmpty(blocks) then
        for _, block in pairs(blocks) do
            block:Close()
            self._BlockNoticePool:Recycle(block)
        end
        self._NoticeBlocks[lineIndex] = {}
    end
end

function XUiFangKuaiFight:CreateNoticeBlock(blockDatas, lineIndex)
    if not XTool.IsTableEmpty(blockDatas) then
        for _, blockData in pairs(blockDatas) do
            local block = self._BlockNoticePool:Create(lineIndex)
            if lineIndex == 1 then
                block.Transform:SetParent(self.Herald1, false)
            else
                block.Transform:SetParent(self.Herald2, false)
            end
            block:Open()
            block:Update(blockData)
            if not self._NoticeBlocks[lineIndex] then
                self._NoticeBlocks[lineIndex] = {}
            end
            table.insert(self._NoticeBlocks[lineIndex], block)
        end
    end
end

--endregion

--region 道具

function XUiFangKuaiFight:RegisterChooseColorBtn()
    self._ColorGridMap = {}
    local isFirst = 1
    local configs = self._Control:GetAllColorTextureConfigs()
    for k, v in pairs(configs) do
        local uiObject = {}
        local grid = isFirst and self.GridColor or XUiHelper.Instantiate(self.GridColor, self.GridColor.parent)
        XUiHelper.InitUiClass(uiObject, grid)
        self._ColorGridMap[k] = grid
        self:RegisterClickEvent(grid, function()
            self:OnClickColor(k)
        end)
        uiObject.ImgOne:SetRawImage(v.StandaloneImage)
        uiObject.ImgOnePass:SetRawImage(v.StandaloneImage)
        uiObject.RImgExpression:SetRawImage(v.Standby[1])
        uiObject.RImgExpressionPass:SetRawImage(v.Standby[1])
        isFirst = false
    end
end

function XUiFangKuaiFight:UpdateChooseColorBtn()
    local colors = self._Control:GetStageColorIds(self._StageId)
    for k, v in pairs(self._ColorGridMap) do
        v.gameObject:SetActiveEx(table.indexof(colors, k))
    end
end

function XUiFangKuaiFight:UpdateItem()
    local itemIndexMap = {}
    local items = self._Control:GetAllItems(self._ChapterId)
    self._EmptyItemGrid = {}
    for index = 1, 4 do
        local uiObject = {}
        local grid = self["BtnProp" .. index]
        local item = items[index]
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.Index = index
        if item then
            if self._ItemIndexMap and not self._ItemIndexMap[index] and self._PlayNewItemAnimList then
                -- 记录该回合获得的道具索引（itemId会重复）
                self._PlayNewItemAnimList[index] = true
            end
            itemIndexMap[index] = true
            uiObject.RImgProp:SetRawImage(item.Icon)
            uiObject.RImgProp2:SetRawImage(item.Icon)
            if self._PlayNewItemAnimList[index] then
                -- 新获得的道具 先隐藏 后面要显示动效
                uiObject.Unactivated.gameObject:SetActiveEx(true)
                uiObject.Unactivated2.gameObject:SetActiveEx(false)
                uiObject.Activate.gameObject:SetActiveEx(false)
                table.insert(self._EmptyItemGrid, uiObject)
            else
                uiObject.Unactivated.gameObject:SetActiveEx(false)
                uiObject.Unactivated2.gameObject:SetActiveEx(self._CurChooseIndex and self._CurChooseIndex ~= index)
                uiObject.Activate.gameObject:SetActiveEx(not self._CurChooseIndex or self._CurChooseIndex == index)
                uiObject.Effect.gameObject:SetActiveEx(self._CurChooseIndex and self._CurChooseIndex == index)
            end
            XUiHelper.RegisterClickEvent(uiObject, uiObject.BtnProp, function()
                self:ShowItemTip(index, item, grid.transform)
            end)
        else
            uiObject.Unactivated.gameObject:SetActiveEx(true)
            uiObject.Unactivated2.gameObject:SetActiveEx(false)
            uiObject.Activate.gameObject:SetActiveEx(false)
            table.insert(self._EmptyItemGrid, uiObject)
        end
    end
    self._ItemIndexMap = itemIndexMap
end

---@param origin XUiGridFangKuaiBlock
function XUiFangKuaiFight:PlayFlyItem(origin)
    if not self._FlyItemPool then
        self._FlyItemPool = {}
        table.insert(self._FlyItemPool, self.RImgFlyItem)
    end
    if not self._EmptyItemGrid then
        XLog.Error("EmptyItemGrid is nil.")
        return
    end
    local itemId = origin.BlockData:GetItemId()
    local dimObj = table.remove(self._EmptyItemGrid, 1)
    if dimObj then
        local itemConfig = self._Control:GetItemConfig(itemId)
        local flyItem = #self._FlyItemPool > 0 and table.remove(self._FlyItemPool, 1)
        if not flyItem then
            flyItem = XUiHelper.Instantiate(self.RImgFlyItem, self.RImgFlyItem.transform.parent)
        end
        local dimPos = flyItem.transform.parent:InverseTransformPoint(dimObj.Transform.position)
        flyItem.gameObject:SetActiveEx(true)
        flyItem:SetRawImage(itemConfig.Icon)
        flyItem.transform.localPosition = self.RImgFlyItem.transform.parent:InverseTransformPoint(origin.RImgItem.transform.position)
        flyItem.transform:DOLocalMove(dimPos, self._Control:GetItemFlyTime()):OnComplete(function()
            flyItem.gameObject:SetActiveEx(false)
            table.insert(self._FlyItemPool, flyItem)
            self:PlayAnimation(string.format("BtnProp%sActivate", dimObj.Index))
            self._PlayNewItemAnimList[dimObj.Index] = nil
            self:UpdateItem()
        end)
    end
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFight:ShowItemTip(index, item, content)
    if not self._Control:CheckExistItem(index, self._ChapterId) then
        return
    end
    if self._PlayNewItemAnimList[index] then
        return
    end

    -- 再次点击则关闭该弹框
    if self._CurChooseIndex == index then
        self:OnClickCancelUseItem()
        return
    end

    local isNeedChooseColor = self._Control:IsItemNeedChooseColor(item.Kind)
    local isItemAddRound = self._Control:IsItemAddRound(item.Kind)

    self.BubbleProp:SetParent(content, false)
    self.BubbleProp.localPosition = index == 2 and BubblePos2 or BubblePos1

    self._CurChooseIndex = index
    self._CurChooseKind = item.Kind
    self.BtnClosePropOther.gameObject:SetActiveEx(true)
    self.BubblePropNormal.gameObject:SetActiveEx(not isNeedChooseColor and not isItemAddRound)
    self.BubblePropCut.gameObject:SetActiveEx(isNeedChooseColor and not isItemAddRound)
    self.BubblePropTime.gameObject:SetActiveEx(isItemAddRound)
    self:UpdateItem()

    if isItemAddRound then
        self.TxtTimeTitle.text = item.Name
        self.TxtTimeDetail.text = item.Desc
        self:ForbidBlock(false, false)
    elseif isNeedChooseColor then
        self.TxtSpecialTitle.text = item.Name
        self.TxtSpecialDetail.text = item.Desc
        self:UpdateChooseColorBtn()
        self:ForbidBlock(false, false)
    else
        self._FirstBlock = nil
        self._SecondBlock = nil
        self.TxtNormalTitle.text = item.Name
        self.TxtNormalDetail.text = item.Desc
        self:ForbidBlock(false, true)
    end
end

function XUiFangKuaiFight:OnClickCancelUseItem()
    self._CurChooseIndex = nil
    self._CurChooseKind = nil
    self.BtnClosePropOther.gameObject:SetActiveEx(false)
    self.BubblePropNormal.gameObject:SetActiveEx(false)
    self.BubblePropCut.gameObject:SetActiveEx(false)
    self.BubblePropTime.gameObject:SetActiveEx(false)
    self:ForbidBlock(true, false)
    self:HideOriginalBlock()
    self:RecoverBlockAlpha()
    self:UpdateItem()
end

function XUiFangKuaiFight:OnClickAddRound()
    local index = self._CurChooseIndex
    self:ReduceItemCount()
    self:OnClickCancelUseItem()
    self._Game:StartAddRoundItem(index)
    -- 增加回合数道具没有执行方块操作的阶段（只有回合数增加） 不需要屏蔽点击
end

function XUiFangKuaiFight:OnClickColor(color)
    local index, kind = self._CurChooseIndex, self._CurChooseKind
    self:ReduceItemCount()
    self:OnClickCancelUseItem()
    self._Game:StartUseColorItem(index, kind, color)
    self:ForbidClick(true)
end

---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:OnClickBlock(block)
    local isSingleLineRemove = self._CurChooseKind == XEnumConst.FangKuai.ItemType.SingleLineRemove
    local isTwoLineExChange = self._CurChooseKind == XEnumConst.FangKuai.ItemType.TwoLineExChange
    local isAdjacentExchange = self._CurChooseKind == XEnumConst.FangKuai.ItemType.AdjacentExchange
    local blockData = block.BlockData

    if isSingleLineRemove then
        self._FirstBlock = block
    else
        if not self._FirstBlock or self._FirstBlock == block then
            self._FirstBlock = block
            if isAdjacentExchange then
                self:ShowOriginalBlock(blockData)
                self:ChangeBlockAlpha(blockData)
            elseif isTwoLineExChange then
                self:ShowOriginalLayer(blockData:GetHeadGrid().y)
            end
            return
        end
        if isTwoLineExChange then
            if self._FirstBlock.BlockData:GetHeadGrid().y == blockData:GetHeadGrid().y then
                return
            end
        elseif isAdjacentExchange then
            -- 方块必须相邻
            if not self:CheckBlockNear(self._FirstBlock.BlockData, blockData) then
                self._FirstBlock = block
                self:ShowOriginalBlock(blockData)
                self:ChangeBlockAlpha(blockData)
                return
            end
        end
        self._SecondBlock = block
    end

    local index, kind = self._CurChooseIndex, self._CurChooseKind
    self:ReduceItemCount()
    self:OnClickCancelUseItem()
    if isSingleLineRemove then
        self._Game:StartUseRemoveItem(index, self._FirstBlock.BlockData)
    else
        self._Game:StartUseExchangeItem(index, kind, self._FirstBlock.BlockData, self._SecondBlock.BlockData)
    end
    self:ForbidClick(true)
end

---@param blockData1 XFangKuaiBlock
---@param blockData2 XFangKuaiBlock
function XUiFangKuaiFight:CheckBlockNear(blockData1, blockData2)
    if blockData1:GetId() == blockData2:GetId() then
        return true
    end
    local firstGrid = blockData1:GetHeadGrid()
    local firstLen = blockData1:GetLen()
    local secondGrid = blockData2:GetHeadGrid()
    local secondLen = blockData2:GetLen()
    return (secondGrid.x + secondLen == firstGrid.x or firstGrid.x + firstLen == secondGrid.x) and (firstGrid.y == secondGrid.y)
end

--endregion

--region 显示方块原先位置

function XUiFangKuaiFight:InitOriginalBlock(len)
    if not self._Original then
        self._Original = {}
        XUiHelper.InitUiClass(self._Original, self.OriginalBlock)
    end
    self._Original.ImgOne.gameObject:SetActiveEx(len == 1)
    self._Original.ImgHead.gameObject:SetActiveEx(len > 1)
    self._Original.ImgTail.gameObject:SetActiveEx(len > 1)
    if len > 1 then
        local tailX = self._Control:GetPosByGridX(len) - 10
        local posY = self._Original.ImgTail.transform.anchoredPosition.y
        self._Original.ImgTail.transform.anchoredPosition = CS.UnityEngine.Vector2(tailX, posY)
    end
end

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:ShowOriginalBlock(blockData)
    self:InitOriginalBlock(blockData:GetLen())
    local posX, posY = self._Control:GetPosByBlock(blockData)
    self.OriginalBlock.localPosition = CS.UnityEngine.Vector3(posX, posY, 0)
    self.OriginalBlock.gameObject:SetActiveEx(true)
end

function XUiFangKuaiFight:ShowOriginalLayer(gridY)
    self:InitOriginalBlock(self._StageConfig.SizeY)
    local posY = self._Control:GetPosByGridY(gridY)
    self.OriginalBlock.localPosition = CS.UnityEngine.Vector3(0, posY, 0)
    self.OriginalBlock.gameObject:SetActiveEx(true)
end

function XUiFangKuaiFight:HideOriginalBlock()
    self.OriginalBlock.gameObject:SetActiveEx(false)
end

--endregion

--region 显示方块所在列

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:ShowCompareBg(blockData)
    local w = self._Control:GetPosByGridX(blockData:GetLen() + 1)
    local h = self.ImageCompare.sizeDelta.y
    local x = self._Control:GetPosByGridX(blockData:GetHeadGrid().x)
    self.PanelCompare.gameObject:SetActiveEx(true)
    self.ImageCompare.sizeDelta = CS.UnityEngine.Vector2(w, h)
    self.PanelCompare.anchoredPosition = CS.UnityEngine.Vector2(x, 0)
end

function XUiFangKuaiFight:UpdateCompareBgPos(posX)
    self.PanelCompare.anchoredPosition = CS.UnityEngine.Vector2(posX, 0)
end

function XUiFangKuaiFight:HideCompareBg()
    self.PanelCompare.gameObject:SetActiveEx(false)
end

--endregion

--region 特效

function XUiFangKuaiFight:ShowWarnEffect()
    local isWarn = false
    local maxY = self._StageConfig.SizeY
    for y = maxY - self._WarnDistance, maxY do
        local blocks = self._Control:GetLayerBlocks(y)
        if not XTool.IsTableEmpty(blocks) then
            isWarn = true
            break
        end
    end
    self.PanelEffect.gameObject:SetActiveEx(isWarn)
end

--endregion

--region 分数

function XUiFangKuaiFight:UpdateScore()
    local score = self._Control:GetScore()
    local scoreIcon = self._Control:GetStageRankIcon(self._StageId, score)
    self.TxtScore.text = score
    self.RImgRankA:SetRawImage(scoreIcon)
end

function XUiFangKuaiFight:ShowCombo()
    local combo = self._Control:GetComboNum()
    if combo >= self._MinShowCombo then
        self:RemoveComboTimer()
        self.PanelCombo.gameObject:SetActiveEx(true)
        self.ComboCountText:TextToSprite(combo)
        self._ComboTimer = XScheduleManager.ScheduleOnce(function()
            self.PanelCombo.gameObject:SetActiveEx(false)
        end, 1000)
        self._Control:PlayComboSound(combo)
    end
end

--endregion

function XUiFangKuaiFight:UpdateRound()
    local round
    if self._Control:IsStageNormal(self._StageId) then
        round = self._Game:GetLeaveRound()
    else
        round = self._Game:GetRound()
    end
    if round then
        self.TxtNum.text = round
        if self._Round and self._Round ~= round then
            self:PlayAnimation("TxtNumQieHuan")
        end
        self._Round = round
    end
end

function XUiFangKuaiFight:OnClickReset()
    self._Control:OpenTip(nil, XUiHelper.GetText("FangKuaiReset"), handler(self, self.RestartGame))
end

function XUiFangKuaiFight:OnClickHelp()
    XLuaUiManager.Open("UiFangKuaiRankDetails", self._StageId)
end

function XUiFangKuaiFight:OnClickExit()
    XLuaUiManager.Remove("UiFangKuaiChapterDetail")
    self._Control:RecordStage(XEnumConst.FangKuai.RecordUiType.Fight, XEnumConst.FangKuai.RecordButtonType.Leave, self._StageId)
    self:Close()
end

-- 方块掉落、生成和上移期间不能移动和使用道具
function XUiFangKuaiFight:ForbidClick(bo)
    self.PanelBlockMask.gameObject:SetActiveEx(bo)
    self.PanelItemMask.gameObject:SetActiveEx(bo)
end

function XUiFangKuaiFight:RemoveTimer()
    self:RemoveComboTimer()
    self:RemoveTipTimer()
    self:RemoveEffectTimer()
end

function XUiFangKuaiFight:RemoveComboTimer()
    if self._ComboTimer then
        XScheduleManager.UnSchedule(self._ComboTimer)
        self._ComboTimer = nil
    end
end

function XUiFangKuaiFight:RemoveTipTimer()
    if self._TipTimer then
        XScheduleManager.UnSchedule(self._TipTimer)
        self._TipTimer = nil
    end
end

function XUiFangKuaiFight:RemoveEffectTimer()
    if self._EffectTimer then
        for _, timer in pairs(self._EffectTimer) do
            XScheduleManager.UnSchedule(timer)
        end
    end
    self._EffectTimer = {}
end

function XUiFangKuaiFight:BlockPoolRecycle(block)
    self._BlockPool:Recycle(block)
end

function XUiFangKuaiFight:ShowTip(desc)
    self:RemoveTipTimer()
    self.PanelTs.gameObject:SetActiveEx(true)
    self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(desc)
    self._TipTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelTs.gameObject:SetActiveEx(false)
    end, 1500)
end

function XUiFangKuaiFight:GetChapterId()
    return self._ChapterId
end

--region 由于道具协议下发时机和飘道具时机不一致 所以这里手动记录了道具数量

function XUiFangKuaiFight:RecordLastItemCount()
    self._RecordItemCount = self._Control:GetItemCount(self._ChapterId)
end

function XUiFangKuaiFight:ReduceItemCount()
    self._RecordItemCount = self._RecordItemCount - 1
    -- 如果使用道具同时获得道具 则服务端前后两次数据是一致的 没法区分哪个道具是新获得的 这里手动把使用掉的道具置空
    table.remove(self._ItemIndexMap)
end

function XUiFangKuaiFight:AddItemCount()
    self._RecordItemCount = self._RecordItemCount + 1
end

--endregion

--region 透明度变化

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:ChangeBlockAlpha(blockData)
    for _, block in pairs(self._BlockMap) do
        local isNear = self:CheckBlockNear(blockData, block.BlockData)
        block:ChangeAlpha(isNear and 1 or self._Alpha)
    end
end

function XUiFangKuaiFight:RecoverBlockAlpha()
    for _, block in pairs(self._BlockMap) do
        block:ChangeAlpha(1)
    end
end

--endregion

--region 引导

function XUiFangKuaiFight:PlayGuide()
    local blockData = self._Game:FindGuideBlock()
    if not blockData then
        return
    end
    local block = self:GetBlock(blockData)
    if not block then
        return
    end
    block:ForceMoveX(3)
end

--endregion

--region 限制多点触屏

function XUiFangKuaiFight:SetCurClickBlockId(id)
    self._CurClickBlock = id
end

function XUiFangKuaiFight:IsOtherClicking(id)
    return self._CurClickBlock and self._CurClickBlock ~= id
end

function XUiFangKuaiFight:ClearClickBlockId()
    self._CurClickBlock = nil
end

--endregion

return XUiFangKuaiFight
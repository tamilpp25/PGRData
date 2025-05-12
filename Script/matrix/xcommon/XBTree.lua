require("XCommon/XClass")

-- 二叉树
---@class XBTree
XBTree = XClass(nil, "XBTree")
function XBTree:Ctor()
    self.Root = nil
end

-- 前序插入节点（总是插入到右子树）
function XBTree:PreOrderInsert(data)
    local newNode = XBTreeNode.New(data)
    if self.Root == nil then
        self.Root = newNode
    else
        self:_PreOrderInsert(self.Root, newNode)
    end
end

function XBTree:_PreOrderInsert(node, newNode)
    if node.Right == nil then
        node.Right = newNode
        newNode.Parent = node -- 记录父节点
        newNode.Depth = node.Depth + 1 -- 更新新节点的深度
    else
        self:_PreOrderInsert(node.Right, newNode)
    end
end

-- 中序插入节点（如果左子树已满，则插入到右子树，否则插入到左子树）
function XBTree:InOrderInsert(data)
    local newNode = XBTreeNode.New(data)
    if self.Root == nil then
        self.Root = newNode
    else
        self:_InOrderInsert(self.Root, newNode)
    end
end

function XBTree:_InOrderInsert(node, newNode)
    if node.Left == nil then
        node.Left = newNode
        newNode.Parent = node -- 记录父节点
        newNode.Depth = node.Depth + 1 -- 更新新节点的深度
    else
        self:_InOrderInsert(node.Left, newNode)
    end
end

-- 后序插入节点（总是插入到左子树）
function XBTree:PostOrderInsert(data)
    local newNode = XBTreeNode.New(data)
    if self.Root == nil then
        self.Root = newNode
    else
        self:_PostOrderInsert(self.Root, newNode)
    end
end

function XBTree:_PostOrderInsert(node, newNode)
    if node.Left == nil then
        node.Left = newNode
        newNode.Parent = node -- 记录父节点
        newNode.Depth = node.Depth + 1 -- 更新新节点的深度
    else
        self:_PostOrderInsert(node.Left, newNode)
    end
end

-- 前序遍历，返回整个节点对象
---@return XBTreeNode[]
function XBTree:PreOrder()
    local result = {}
    self:_PreOrder(self.Root, result)
    return result
end

function XBTree:_PreOrder(node, result)
    if node ~= nil then
        table.insert(result, node) -- 插入整个节点对象
        self:_PreOrder(node.Left, result)
        self:_PreOrder(node.Right, result)
    end
end

-- 中序遍历，返回整个节点对象
---@return XBTreeNode[]
function XBTree:InOrder()
    local result = {}
    self:_InOrder(self.Root, result)
    return result
end

function XBTree:_InOrder(node, result)
    if node ~= nil then
        self:_InOrder(node.Left, result)
        table.insert(result, node) -- 插入整个节点对象
        self:_InOrder(node.Right, result)
    end
end

-- 后序遍历，返回整个节点对象
---@return XBTreeNode[]
function XBTree:PostOrder()
    local result = {}
    self:_PostOrder(self.Root, result)
    return result
end

function XBTree:_PostOrder(node, result)
    if node ~= nil then
        self:_PostOrder(node.Left, result)
        self:_PostOrder(node.Right, result)
        table.insert(result, node) -- 插入整个节点对象
    end
end

-- 层序插入节点
function XBTree:LevelOrderInsert(data)
    local newNode = XBTreeNode.New(data, 1) -- 创建新节点，初始深度为1
    if self.Root == nil then
        self.Root = newNode
    else
        local queue = {self.Root}
        while true do
            local node = table.remove(queue, 1)
            if node.Left == nil then
                node.Left = newNode
                newNode.Depth = node.Depth + 1 -- 更新新节点的深度
                newNode.Parent = node -- 记录父节点
                break
            else
                table.insert(queue, node.Left)
            end
            
            if node.Right == nil then
                node.Right = newNode
                newNode.Depth = node.Depth + 1 -- 更新新节点的深度
                newNode.Parent = node -- 记录父节点
                break
            else
                table.insert(queue, node.Right)
            end
        end
    end
end

-- 层序遍历
---@return XBTreeNode[]
function XBTree:LevelOrder()
    local queue = {self.Root}
    local result = {}
    
    while #queue > 0 do
        local currentNode = table.remove(queue, 1)
        if currentNode ~= nil then
            table.insert(result, currentNode) -- 直接存储节点对象
            
            if currentNode.Left ~= nil then
                table.insert(queue, currentNode.Left)
            end
            
            if currentNode.Right ~= nil then
                table.insert(queue, currentNode.Right)
            end
        end
    end
    
    return result
end

-- 根据深度返回该层的节点
---@param depth number
---@return XBTreeNode[]
function XBTree:GetNodesByDepth(depth)
    local queue = {self.Root}
    local result = {}
    local currentDepth = 1 -- 根节点的深度为1
    
    while #queue > 0 do
        local levelSize = #queue
        for i = 1, levelSize do
            local node = table.remove(queue, 1)
            if node.Depth == depth then
                table.insert(result, node)
            end
            
            if node.Left ~= nil then
                table.insert(queue, node.Left)
            end
            
            if node.Right ~= nil then
                table.insert(queue, node.Right)
            end
        end
        currentDepth = currentDepth + 1
    end
    
    return result
end

-- 返回当前树的总深度
function XBTree:GetTreeDepth()
    return self:_GetTreeDepth(self.Root)
end

function XBTree:_GetTreeDepth(node)
    if node == nil then
        return 0
    else
        local leftDepth = self:_GetTreeDepth(node.Left)
        local rightDepth = self:_GetTreeDepth(node.Right)
        return math.max(leftDepth, rightDepth) + 1
    end
end
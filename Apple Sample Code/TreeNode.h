#import <Foundation/Foundation.h>

@interface TreeNode : NSObject {
@protected
    TreeNode *nodeParent;
    id nodeData;
    NSMutableArray *nodeChildren;
}

+ (id)treeNodeWithData:(id)data;
- (id)initWithData:(id)data parent:(TreeNode *)parent children:(NSArray *)children;

- (void)setNodeData:(id)data;
- (id)nodeData;

- (void)setNodeParent:(TreeNode *)parent;
- (TreeNode *)nodeParent;

- (void)insertChild:(TreeNode *)child atIndex:(NSInteger)index;
- (void)insertChildren:(NSArray *)children atIndex:(NSInteger)index;
- (void)removeChild:(TreeNode *)child;
- (void)removeFromParent;

- (NSInteger)indexOfChild:(TreeNode *)child;
- (NSInteger)indexOfChildIdenticalTo:(TreeNode *)child;

- (NSInteger)numberOfChildren;
- (NSArray *)children;
- (TreeNode *)firstChild;
- (TreeNode *)lastChild;
- (TreeNode *)childAtIndex:(NSInteger)index;

// returns YES if 'node' is an ancestor.
- (BOOL)isDescendantOfNode:(TreeNode *)node;

// returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
- (BOOL)isDescendantOfNodeInArray:(NSArray *)nodes;

// sort children using the compare: method in nodeData
- (void)recursiveSortChildren;

// Returns the minimum nodes from 'allNodes' required to cover the nodes in 'allNodes'.
// This methods returns an array containing nodes from 'allNodes' such that no node in
// the returned array has an ancestor in the returned array.
+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)allNodes;

@end

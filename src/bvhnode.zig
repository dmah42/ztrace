const std = @import("std");
const aabb = @import("aabb.zig");
const Hit = @import("hit.zig").Hit;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;

const AABB = aabb.AABB;

fn box_compare(a: Sphere, b: Sphere, axis: usize) bool {
    const box_a = a.bound();
    const box_b = b.bound();

    return box_a.minimum.v[axis] < box_b.minimum.v[axis];
}

fn x_comparator(context: void, a: Sphere, b: Sphere) bool {
    return box_compare(a, b, 0);
}
fn y_comparator(context: void, a: Sphere, b: Sphere) bool {
    return box_compare(a, b, 1);
}
fn z_comparator(context: void, a: Sphere, b: Sphere) bool {
    return box_compare(a, b, 2);
}

const NodeContentsTag = enum {
    sphere,
    node,
};

const NodeContents = union(NodeContentsTag) {
    sphere: Sphere,
    node: *BVHNode,
};

pub const BVHNode = struct {
    box: AABB,

    left: NodeContents,
    right: NodeContents,

    pub fn init(alloc: *std.mem.Allocator, objects: []Sphere, rand: *std.rand.Random) std.mem.Allocator.Error!*BVHNode {
        const axis = rand.intRangeLessThan(usize, 0, 3);

        var node = try alloc.create(BVHNode);

        const span = objects.len;
        if (span == 1) {
            node.left = .{ .sphere = objects[0] };
            node.right = .{ .sphere = objects[0] };
        } else if (span == 2) {
            if (if (axis == 0) x_comparator({}, objects[0], objects[1]) else if (axis == 1) y_comparator({}, objects[0], objects[1]) else z_comparator({}, objects[0], objects[1])) {
                node.left = .{ .sphere = objects[0] };
                node.right = .{ .sphere = objects[1] };
            } else {
                node.left = .{ .sphere = objects[1] };
                node.right = .{ .sphere = objects[0] };
            }
        } else {
            switch (axis) {
                0 => std.sort.sort(Sphere, objects, {}, x_comparator),
                1 => std.sort.sort(Sphere, objects, {}, x_comparator),
                2 => std.sort.sort(Sphere, objects, {}, x_comparator),
                else => std.log.err("something's gone horribly wrong", .{}),
            }

            const mid = span / 2;
            node.left = .{ .node = try BVHNode.init(alloc, objects[0..mid], rand) };
            node.right = .{ .node = try BVHNode.init(alloc, objects[mid..span], rand) };
        }

        const left_box = if (node.left == .sphere) node.left.sphere.bound() else node.left.node.bound();
        const right_box = if (node.right == .sphere) node.right.sphere.bound() else node.right.node.bound();

        node.box = aabb.surrounding(left_box, right_box);

        return node;
    }

    pub fn bound(self: BVHNode) AABB {
        return self.box;
    }

    pub fn intersect(self: BVHNode, r: Ray, t_min: f64, t_max: f64) ?Hit {
        if (!self.box.hit(r, t_min, t_max)) {
            return null;
        }

        const maybeHitLeft = if (self.left == .sphere) self.left.sphere.intersect(r, t_min, t_max) else self.left.node.intersect(r, t_min, t_max);
        var maybeHitRight: ?Hit = null;
        if (maybeHitLeft) |hitLeft| {
            maybeHitRight = if (self.right == .sphere) self.right.sphere.intersect(r, t_min, hitLeft.t) else self.right.node.intersect(r, t_min, hitLeft.t);
            if (maybeHitRight) |_| {
                return maybeHitRight;
            }
            return maybeHitLeft;
        } else {
            return if (self.right == .sphere) self.right.sphere.intersect(r, t_min, t_max) else self.right.node.intersect(r, t_min, t_max);
        }
    }
};

import CoreTransferable
import GroupActivities

struct PersonasActivity: GroupActivity, Transferable, Sendable {
    var metadata: GroupActivityMetadata = {
        var metadata = GroupActivityMetadata()
        metadata.title = "XRDining"
        return metadata
    }()
}

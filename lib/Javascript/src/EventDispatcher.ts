
// An object that maps an event name to an EventTarget object reference
type NamedEventTarget = {
    name: string; // maps to Event.type e.g. 'availabilitychanged', 'gattserverdisconnected' etc
    target: EventTarget;
}

// Forwards events to an EventTarget for a given event name within some namespace
class NamespacedEventDispatcher {
    // TODO: change to a dictionary
    private targets: NamedEventTarget[];

    constructor(
        public readonly id: string
    ) {
        this.id = id;
        this.targets = [];
    }

    public isEmpty = () => {
        return this.targets.length === 0;
    }

    public addTarget = (name: string, target: EventTarget) => {
        this.targets.push({ name, target });
    }

    public removeTarget = (name: string) => {
        this.targets = this.targets.filter(t => t.name !== name);
    }

    public postMessage = (event: Event) => {
        const entry = this.targets.find(t => t.name === event.type);
        if (entry) {
            entry.target.dispatchEvent(event);
        }
    }
}

// Provides a way to indirectly dispatch events to a captured EventTarget object reference
class GlobalEventDispatcher {
    // TODO: change to a dictionary
    private dispatchers: NamespacedEventDispatcher[];

    constructor() {
        this.dispatchers = [];
    }

    public addTarget = (id: string, name: string, target: EventTarget) => {
        let dispatcher = this.dispatchers.find(d => d.id === id);
        if (!dispatcher) {
            dispatcher = new NamespacedEventDispatcher(id);
            this.dispatchers.push(dispatcher);
        }
        dispatcher.addTarget(name, target);
    }

    public removeTarget = (id: string, name: string) => {
        const dispatcher = this.dispatchers.find(d => d.id === id);
        if (dispatcher) {
            dispatcher.removeTarget(name);
        }
        if (dispatcher.isEmpty()) {
            this.dispatchers = this.dispatchers.filter(d => d.id !== id);
        }
    }

    public removeAllTargets = (id: string) => {
        this.dispatchers = this.dispatchers.filter(d => d.id !== id);
    }

    public postMessage = (id: string, event: Event) => {
        const dispatcher = this.dispatchers.find(d => d.id === id);
        if (dispatcher) {
            dispatcher.postMessage(event);
        }
    }
}

export const mainDispatcher = new GlobalEventDispatcher();

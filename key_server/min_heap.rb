# min_heap.rb
#
# A simple MinHeap implementation for Ruby.
# It stores elements as [priority, value] and always keeps the element
# with the lowest priority at the top (index 0).
# This is used by the KeyManager to efficiently manage key expiry times.

class MinHeap
    def initialize
      @heap = []
    end
  
    # Inserts a new element [priority, value] into the heap.
    # priority: The value used for ordering (e.g., a timestamp).
    # value: The actual data associated with the priority (e.g., a key_id).
    def insert(item)
      @heap << item # Add to the end
      bubble_up(@heap.length - 1) # Restore heap property by bubbling up
    end
  
    # Removes and returns the element with the lowest priority (the root).
    # Returns nil if the heap is empty.
    def extract_min
      return nil if @heap.empty?
      return @heap.pop if @heap.length == 1
  
      min_item = @heap[0] # The minimum element is at the root
      @heap[0] = @heap.pop # Replace root with the last element
      bubble_down(0) # Restore heap property by bubbling down
      min_item
    end
  
    # Returns the element with the lowest priority without removing it.
    # Returns nil if the heap is empty.
    def peek
      @heap[0]
    end
  
    # Returns the current size of the heap.
    def size
      @heap.length
    end
  
    # Checks if the heap is empty.
    def empty?
      @heap.empty?
    end
  
    private
  
    # Calculates the parent index for a given child index.
    def parent_index(index)
      (index - 1) / 2
    end
  
    # Calculates the left child index for a given parent index.
    def left_child_index(index)
      2 * index + 1
    end
  
    # Calculates the right child index for a given parent index.
    def right_child_index(index)
      2 * index + 2
    end
  
    # Restores the heap property by moving an element up the heap
    # if its priority is less than its parent's.
    def bubble_up(index)
      while index > 0 && @heap[index][0] < @heap[parent_index(index)][0]
        # Swap current element with its parent
        @heap[index], @heap[parent_index(index)] = @heap[parent_index(index)], @heap[index]
        index = parent_index(index) # Move up to the parent's position
      end
    end
  
    # Restores the heap property by moving an element down the heap
    # if its priority is greater than its children's.
    def bubble_down(index)
      loop do
        left_idx = left_child_index(index)
        right_idx = right_child_index(index)
        smallest = index # Assume current node is the smallest
  
        # Check if left child exists and has lower priority
        if left_idx < @heap.length && @heap[left_idx][0] < @heap[smallest][0]
          smallest = left_idx
        end
  
        # Check if right child exists and has even lower priority
        if right_idx < @heap.length && @heap[right_idx][0] < @heap[smallest][0]
          smallest = right_idx
        end
  
        # If the smallest is not the current node, swap and continue bubbling down
        if smallest != index
          @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
          index = smallest
        else
          break # Heap property restored
        end
      end
    end
  end
  
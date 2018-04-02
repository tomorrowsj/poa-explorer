defmodule Explorer.Indexer.Sequence do
  use Agent

  def start_link(initial_ranges, range_start, step) do
    Agent.start_link(fn ->
      %{
        current: range_start,
        step: step,
        mode: :infinite,
        que: :queue.from_list(initial_ranges)
      }
    end)
  end

  def inject_range(sequencer, range) do
    Agent.update(sequencer, fn state ->
      %{state | que: :queue.in(range, state.que)}
    end)
  end

  def cap(sequencer) do
    Agent.update(sequencer, fn state ->
      %{state | mode: :finite}
    end)
  end

  def build_stream(sequencer) do
    Stream.resource(
      fn -> sequencer end,
      fn seq ->
        case pop(seq) do
          :halt -> {:halt, seq}
          range -> {[range], seq}
        end
      end,
      fn seq -> seq end
    )
  end

  def pop(sequencer) do
    Agent.get_and_update(sequencer,fn %{current: current, step: step} = state ->
      case {state.mode, :queue.out(state.que)} do
        {_, {{:value, {starting, ending}}, new_que}} ->
          {{starting, ending}, %{state | que: new_que}}

        {:infinite, {:empty, new_que}} ->
          {{current, current + step - 1}, %{state | current: current + step, que: new_que}}

        {:finite, {:empty, new_que}} ->
          {:halt, %{state | que: new_que}}
      end
    end)
  end
end

import pickle
import unittest

from garage.envs.mujoco.hill.swimmer3d_hill_env import Swimmer3DHillEnv


class TestSwimmer3DHillEnv(unittest.TestCase):

    def test_pickleable(self):

        env = Swimmer3DHillEnv(regen_terrain=False)
        round_trip = pickle.loads(pickle.dumps(env))
        assert round_trip
        assert round_trip.difficulty == env.difficulty

        round_trip.reset()
        for _ in range(10):
            _, _, done, _ = round_trip.step(round_trip.action_space.sample())
            round_trip.render()
            if done:
                break
        round_trip.close()
